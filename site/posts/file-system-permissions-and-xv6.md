# How File Systems Store User Permissions - A Practical Guide with xv6


Have you ever wondered how operating systems like Ubuntu or Debian store user file permissions? I have; and set about on a mini project to understand the how and the why.

*This is an ongoing, evolving article - text and diagrams are very likely to be added and changed as I delve more into the system and find better ways of explaining these concepts.*

## A High Level Overview - Inode

"In a Unix-style file system, an index node, informally referred to as an inode, is a data structure used to represent a filesystem object, which can be one of various things including a file or a directory." starts the wikipedia entry.

An inode contains the following information about a file:

* Mode/permission (protection)
* Owner ID
* Group ID
* Size of file
* Number of hard links to the file
* Time last accessed
* Time last modified
* Time inode last modified 

Later on this was adopted into a POSIX standard:

* The size of the file in bytes.
* Device ID (this identifies the device containing the file).
* The User ID of the file's owner.
* The Group ID of the file.
* The file mode which determines the file type and how the file's owner, its group, and others can access the file.
* Additional system and user flags to further protect the file (limit its use and modification).
* Timestamps telling when the inode itself was last modified (ctime, inode change time), the file content last modified (mtime, modification time), and last accessed (atime, access time).
* A link count telling how many hard links point to the inode.
* Pointers to the disk blocks that store the file's contents (see inode pointer structure).


### The xv6 inode


The base release of xv6 defines the following for an inode:
        
        // from file.h
        // in-memory copy of an inode
        struct inode {
          uint dev;           // Device number
          uint inum;          // Inode number
          int ref;            // Reference count
          int flags;          // I_BUSY, I_VALID

          short type;         // copy of disk inode
          short major;
          short minor;
          short nlink;
          uint size;
          uint addrs[NDIRECT+1];
        };

As you can see there is nowhere to store any information about user permissions, because the bare release has no concept of user permissions.

It is also worth pointing out that this isn't the only place in xv6 where <code>inode</code> is defined:

        // from fs.h
        // On-disk inode structure
        struct dinode {
          short type;           // File type
          short major;          // Major device number (T_DEV only)
          short minor;          // Minor device number (T_DEV only)
          short nlink;          // Number of links to inode in file system
          uint size;            // Size of file (bytes)
          uint addrs[NDIRECT+1];   // Data block addresses
        };

There are obviously a few missing attributes from the on-disk inode structure v.s. the in-memory structure. Some of these are obvious e.g. the <code>flags</code> parameter - when storing an inode on disk there is no need to worry about whether it is busy or not - this only becomes an issue once it is being used i.e. is in memory. Others like <code>inum</code> need further explanation. (**TODO** - Explain how inum is populated)

## Laying the Groundwork - Updating our structs

We want to move our version of xv6 towards supporting file user permissions - while we are not aiming for POSIX compatibility, we will be inspired by the POSIX design and use that to guide us in our implementation.

We will start from the ground up and first build the concept into our structs.

It is clear from the POSIX specification that there are three attributes that are required for enforcing file permissions - the user id, the group id and the file mode (read, write, execute for the owner, group and others). xv6 does not come with the concept of a user (at least one with an id) and groups and modes are also not present so we will have to define them.

<figure style="text-align:center">
  <img src="/images/xv6/inode.png"/>
  <figcaption>Our proposed new in-memory inode structure.</figcaption>
</figure>

Further, it is obvious that these attributes have to be stored in both the in-memory structure and on-disk as we will want these attributes to survive a power cycle and we will be wanting to have an in memory cached version when we want to perform checks later on. So, now that that is all settled, let us start by introducing these attributes to our structures:

        // fs.h
        // On-disk inode structure
        struct dinode {
          short type;           // File type
          short major;          // Major device number (T_DEV only)
          short minor;          // Minor device number (T_DEV only)
          short nlink;          // Number of links to inode in file system
          short ownerid;        // The ID of the user who owns the file.
          short groupid;        // The ID of the group who owns the file.
          uint mode;           // The files mode e.g. 0700
          uint size;            // Size of file (bytes)
          uint addrs[NDIRECT+1];   // Data block addresses
        }

        // file.h
        // in-memory copy of an inode
        struct inode {
          uint dev;           // Device number
          uint inum;          // Inode number
          int ref;            // Reference count
          int flags;          // I_BUSY, I_VALID

          short type;         // copy of disk inode
          short major;
          short minor;
          short nlink;
          short ownerid;      // The ID of the user who owns the file.
          short groupid;      // The ID of the group who owns the file.
          uint mode;         // The files mode e.g. 0700
          uint size;
          uint addrs[NDIRECT+1];
        };

Great! We now have defined our new attributes. Now we can start using them. The first thing we will want to do is ensure that we can see these values from inside xv6 - ideally as part of the <code>ls</code> command.

xv6 has a utility code file called <code>mkfs.c</code> which is responsible for constructing the on-disk file system during the compilation process. We are going to first add some defaults to this file so that we can later see these values in command.


        // mkfs.c
        uint
        ialloc(ushort type)
        {
          uint inum = freeinode++;
          struct dinode din;

          bzero(&din, sizeof(din));
          din.type = xshort(type);
          din.nlink = xshort(1);
          din.size = xint(0);
          
          // Set notable defaults for our permission attributes.
          din.ownerid = xshort(99);
          din.groupid = xshort(1);
          din.mode = xint(0x0700);

          winode(inum, &din);
          return inum;
        }

There is one more thing we need to do before this will work. We have altered the size of our inode structures from 512 bytes to 576 bytes - this makes the maths a bit messy, and there are a number of places in xv6 that assume inodes and other on-file data structures lie on block boundaries - to make like easy for ourselves and to minimize the amount of code we have to touch that isn't directly related to our current task we are simply going to reduce the number of data block addresses <code>NDIRECT</code> from 12 to 10 and thus reduce our structure back to 512 bites.

## Loading our new attributes into memory

We now need to ensure that these values get loaded into memory. To start we need to read the data from our on-disk structure into our in-memory structure. This is done in the <code>ilock</code> function in <code>fs.c</code> (see line 28-31 below):

        // fs.c
        // Lock the given inode.
        // Reads the inode from disk if necessary.
        void
        ilock(struct inode *ip)
        {
          struct buf *bp;
          struct dinode *dip;

          if(ip == 0 || ip->ref < 1)
            panic("ilock");

          acquire(&icache.lock);
          while(ip->flags & I_BUSY)
            sleep(ip, &icache.lock);
          ip->flags |= I_BUSY;
          release(&icache.lock);

          if(!(ip->flags & I_VALID)){
            bp = bread(ip->dev, IBLOCK(ip->inum));
            dip = (struct dinode*)bp->data + ip->inum%IPB;
            ip->type = dip->type;
            ip->major = dip->major;
            ip->minor = dip->minor;
            ip->nlink = dip->nlink;
            ip->size = dip->size;
            
            // Read ownership permissions into memory.
            ip->ownerid = dip->ownerid;
            ip->groupid = dip->groupid;
            ip->mode = dip->mode;

            memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
            brelse(bp);
            ip->flags |= I_VALID;
            if(ip->type == 0)
              panic("ilock: no type");
          }
        }

And that is it! Our attributes are loaded into memory, we can now kick off <code>make qemu</code> and load up our operating system. Ofcourse, there is a little more work to do to make these values useful.

## Enter stat.h

In userland, <code>stat.h</code> contains an in-memory structure which is used to store file attributes that we would like to utilize in applications. Currently, this has no concept of our new attributes, so let's add them:

        // stat.h
        #define T_DIR  1   // Directory
        #define T_FILE 2   // File
        #define T_DEV  3   // Device

        struct stat {
          short type;  // Type of file
          int dev;     // File system's disk device
          uint ino;    // Inode number
          short nlink; // Number of links to file
          short ownerid; // The owner of the file
          short groupid; // The group owner of the file
          uint mode;     // The permissions mode of the file
          uint size;   // Size of file in bytes
        };

The actual initialization of these values is performed back in <code>fs.c</code> - so back we go:

        // fs.c
        // Copy stat information from inode.
        void
        stati(struct inode *ip, struct stat *st)
        {
          st->dev = ip->dev;
          st->ino = ip->inum;
          st->type = ip->type;
          st->nlink = ip->nlink;
          st->size = ip->size;
          st->ownerid = ip->ownerid;
          st->groupid = ip->groupid;
          st->mode = ip->mode;
        }

We now have everything we need to start using these values in a userland application. So let's print these values out when we call <code>ls</code>.

This is pretty straight forward since we have done all the hard work, we just need to adjust the printf statements:

          // ls.c
          case T_FILE:
            printf(1, "%s %d %d %d %x %d %d\n", fmtname(path), st.type, st.ownerid, st.groupid, st.mode, st.ino, st.size);
            break;
            
One more call to <code>make qemu</code> and we get our first sample run:

        xv6...
        cpu1: starting
        cpu0: starting
        init: starting sh
        $ ls
        .               1 99 1 700 1 512
        ..              1 99 1 700 1 512
        README          2 99 1 700 2 1972
        cat             2 99 1 700 3 11523
        echo            2 99 1 700 4 10924
        forktest        2 99 1 700 5 6969
        grep            2 99 1 700 6 13011
        init            2 99 1 700 7 11317
        kill            2 99 1 700 8 10920
        ln              2 99 1 700 9 10878
        ls              2 99 1 700 10 12953
        mkdir           2 99 1 700 11 10985
        rm              2 99 1 700 12 10966
        sh              2 99 1 700 13 20545
        stressfs        2 99 1 700 14 11488
        usertests       2 99 1 700 15 46539
        wc              2 99 1 700 16 12029
        zombie          2 99 1 700 17 10670
        console         3 0 0 0 18 0
        $ 

Yes! We did it, there are our values showing up for all to see. This is a great first start, but this is pretty much all our code is good for at the moment, we can now start examining how we can use these values to enforce user permissions.

The complete code up until now can be found [on github](https://github.com/s-rah/xv6-permissions/commit/b173bd5491179acd21c7da04627699efab26f7cf)

## Modifying File Permissions

Before we start playing around with checking and enforcement, we first need a way to easily modify file permissions. We are going to build a simple version of <code>chmod</code> command. This section will take us through building the application, system call and copying the permission changes back into the file system.

<h4>Implementing a System Call</h4>

Our syscall is going to have the same API as the [linux version of chmod](http://man7.org/linux/man-pages/man2/chmod.2.html):

           int chmod(const char *pathname, mode_t mode);

The first thing we are going to do is add out sys call number in <code>syscall.h</code>

        #define SYS_chmod  22

And in <code>syscall.c</code> add the references to our new system call:

        extern int sys_chmod(void);
        
and our function pointers:

        static int (*syscalls[])(void) = {
        [SYS_fork]    sys_fork,
        [SYS_exit]    sys_exit,
        [SYS_wait]    sys_wait,
        [SYS_pipe]    sys_pipe,
        [SYS_read]    sys_read,
        [SYS_kill]    sys_kill,
        [SYS_exec]    sys_exec,
        [SYS_fstat]   sys_fstat,
        [SYS_chdir]   sys_chdir,
        [SYS_dup]     sys_dup,
        [SYS_getpid]  sys_getpid,
        [SYS_sbrk]    sys_sbrk,
        [SYS_sleep]   sys_sleep,
        [SYS_uptime]  sys_uptime,
        [SYS_open]    sys_open,
        [SYS_write]   sys_write,
        [SYS_mknod]   sys_mknod,
        [SYS_unlink]  sys_unlink,
        [SYS_link]    sys_link,
        [SYS_mkdir]   sys_mkdir,
        [SYS_close]   sys_close,
        [SYS_chmod]   sys_chmod,
        };

We can't forget the function definition in <code>user.h</code>

        int chmod(char *, int);

And the macro in <code>usys.S</code>

        SYSCALL(chmod)

Yay! That is all of our plumbing done. Now we can start writing our system call (we are going to put ours in <code>sysfile.c</code>):

        int sys_chmod(void) {
            char *path;
            int mode;
            struct inode *ip;
            if(argstr(0, &path) < 0 || argint(1, &mode) < 0)
                return -1;

            begin_op();
            if((ip = namei(path)) == 0) {
                end_op();
                return -1;
            }
            ilock(ip);
            ip->mode = mode;
            iupdate(ip); // Copy to disk
            iunlockput(ip);
            end_op();
            return 0;
        }
       
And finally to ensure this whole integration works, we will write a quick little version of chmod which makes use of this system call:

        #include "types.h"
        #include "stat.h"
        #include "user.h"

        int
        main(int argc, char *argv[])
        {
            if(argc < 3) exit();
            
            int fd;
            struct stat st;
            char * path = argv[2];
            if((fd = open(path, 0)) < 0) {
                printf(2, "chmod: cannot open %s\n", path);
                exit();
            }

            if(fstat(fd, &st) < 0) {
                printf(2, "chmod: cannot stat %s\n", path);
                close(fd);
                exit();
            }
            
            int mode = st.mode;
            close(fd);
            
            if(strcmp(argv[1], "-x") == 0) {
                chmod(path, 0x100 ^ mode);
            } else if(strcmp(argv[1], "+x") == 0) {
                chmod(path, 0x100 ^ mode);
            }
            exit();
        }
        
And give it a go...

        cpu1: starting
        cpu0: starting
        init: starting sh
        $ ls
        .              1 99 1 777 1 512
        ..             1 99 1 777 1 512
        README         2 99 1 777 2 1972
        cat            2 99 1 777 3 11553
        chmod          2 99 1 777 4 11591
        echo           2 99 1 777 5 10954
        forktest       2 99 1 777 6 6999
        grep           2 99 1 777 7 13041
        init           2 99 1 777 8 11347
        kill           2 99 1 777 9 10954
        ln             2 99 1 777 10 10908
        ls             2 99 1 777 11 12963
        mkdir          2 99 1 777 12 11015
        rm             2 99 1 777 13 11000
        sh             2 99 1 777 14 20575
        stressfs       2 99 1 777 15 11518
        usertests      2 99 1 777 16 46569
        wc             2 99 1 777 17 12063
        zombie         2 99 1 777 18 10700
        console        3 0 0 0 19 0
        $ chmod -x README
        $ ls
        .              1 99 1 777 1 512
        ..             1 99 1 777 1 512
        README         2 99 1 677 2 1972
        cat            2 99 1 777 3 11553
        chmod          2 99 1 777 4 11591
        echo           2 99 1 777 5 10954
        forktest       2 99 1 777 6 6999
        grep           2 99 1 777 7 13041
        init           2 99 1 777 8 11347
        kill           2 99 1 777 9 10954
        ln             2 99 1 777 10 10908
        ls             2 99 1 777 11 12963
        mkdir          2 99 1 777 12 11015
        rm             2 99 1 777 13 11000
        sh             2 99 1 777 14 20575
        stressfs       2 99 1 777 15 11518
        usertests      2 99 1 777 16 46569
        wc             2 99 1 777 17 12063
        zombie         2 99 1 777 18 10700
        console        3 0 0 0 19 0
        $ 


It works! We now have simple way of reading file permissions and modifying them to some degree.

The complete code up until now can be found [on github](https://github.com/s-rah/xv6-permissions/commit/cdf5ce51a1377a2e1937d4a0da14177c96fb4772)

## Checking File Permissions

We would now like to use our newly minted file permissions to actually control some behaviour.

In Linux kernel the magic happens in [fs/namei.c](https://github.com/torvalds/linux/blob/master/fs/namei.c#L290), this function is utilized from many places inside the kernel usually through the following code path:

        do_filp_open()
        finish_open()
        may_open()
        inode_permission()
        generic_permission()
        acl_permission_check()

This code path is utilized, among others, by [fs/exec.c](https://github.com/torvalds/linux/blob/master/fs/exec.c#L751) to check whether the current user has sufficient privileges to execute the file.

Our OS is much simpler (and currently chmod only allows the user to change the executable bit) - we are going to put some code into <code>exec.c</code> to check that the node we are trying to execute does indeed have this executable bit.

## References

* [1] [https://en.wikipedia.org/wiki/Inode](https://en.wikipedia.org/wiki/Inode)
* [2] [POSIX sys/stat.h](http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_stat.h.html)
* [3] [How do file permissions attributed work? Unix Stack Exchange](https://unix.stackexchange.com/questions/79955/how-do-file-permissions-attributes-work-kernel-level-fs-level-or-both)
* [4] [Linux acl_permission_check call path. Unix Stack Exchange](https://unix.stackexchange.com/questions/61408/linux-kernel-uid-and-gid-vs-etc-passwd/61420#61420)
* [5] [Credentials in the Linux Kernel](https://www.kernel.org/doc/Documentation/security/credentials.txt)
* [6] [How Linux Capabilities Work](http://www.cis.syr.edu/~wedu/seed/Documentation/Linux/How_Linux_Capability_Works.pdf)
