# Having Fun with GitHub Email Settings


This is the story of a small vulnerability in how GitHub validated emails...

<meta property="og:type" content="article"/>
<meta property="og:title" content="Having Fun with GitHub Email Settings"/>
<meta property="og:image" content="//sarahjamielewis.com/images/github/endgame.png"/>
<meta property="og:description" content="This is the story of a small vulnerability in how GitHub validated emails. By Sarah Jamie Lewis"/>
<meta property="og:locale" content="en_CA"/>
<meta property="og:url" content="https://sarahjamielewis.com/posts/fun-with-github.html" />
<meta property="og:site_name" content="Sarah Jamie Lewis" />


<meta name="twitter:card" content="summary" />
<meta name="twitter:site" content="@SarahJamieLewis" />
<meta name="twitter:title" content="Having Fun with GitHub Email Settings" />
<meta name="twitter:description" content="This is the story of a small vulnerability in how GitHub validated emails..." />
<meta name="twitter:image" content="//sarahjamielewis.com/images/github/endgame.png" />
<div itemscope itemtype="http://schema.org/BlogPosting">
  <meta itemscope itemprop="mainEntityOfPage"  itemType="https://schema.org/WebPage" itemid="https://sarahjamielewis.com/posts/fun-with-github.html"/> 
  <h2 itemprop="headline">Having Fun with GitHub Email Settings</h2>
  <h3 itemprop="author" itemscope itemtype="https://schema.org/Person">
    By <span itemprop="name">Sarah Jamie Lewis</span>
  </h2>
  <span itemprop="description">This is the story of a small vulnerability in how GitHub validated emails...</span>
  <meta itemprop="datePublished" content="2015-03-14T08:00:00+08:00"/>
  <meta itemprop="dateModified" content="2015-12-14T08:00:00+08:00"/>
  <div itemprop="publisher" itemscope itemtype="https://schema.org/Organization">
    <meta itemprop="name" content="Sarah Jamie Lewis">
    <div itemprop="logo" itemscope itemtype="https://schema.org/ImageObject">
      <meta itemprop="url" content="https://sarahjamielewis.com/images/sarah.png">
      <meta itemprop="width" content="400">
      <meta itemprop="height" content="400">
    </div>
  </div>
      <div itemprop="image" itemscope itemtype="https://schema.org/ImageObject">
       <meta itemprop="url" content="https://sarahjamielewis.com/images/github/endgame.png">
       <meta itemprop="width" content="517">
       <meta itemprop="height" content="192">
      </div>
</div>


<blockquote class="twitter-tweet tw-align-center" lang="en"><p lang="en" dir="ltr">Thanks to <a href="https://twitter.com/SarahJamieLewis">@SarahJamieLewis</a> for reporting an issue with profile email addresses and her donation to <a href="https://twitter.com/torproject">@torproject</a>. <a href="https://t.co/TgqcV5LLje">https://t.co/TgqcV5LLje</a></p>&mdash; GitHub Security (@GitHubSecurity) <a href="https://twitter.com/GitHubSecurity/status/675047561401647105">December 10, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

GitHub is very careful about emails - if you try to add another email to
your account, and that email is already associated with an existing account - you will
receive an error:

<figure style="text-align:center">
  <img src="/images/github/email-error.png"/>
  <figcaption>GitHub won't allow you to add an email that already exists</figcaption>
</figure>

This is for good reason. GitHub allows users to add other users to private
organizations and repositories by their email address, as such, the 
email settings screen does not allow you to add an email address that belongs
to another user.

However, there is another screen which allows you to set emails, the *Edit Profile*
page. The GitHub UI will only let you select emails which already exist in
your email screen.

However, should you simply construct the PUT request yourself, with an email
that you want to use...

<figure style="text-align:center">
  <img src="/images/github/emailselect.png"/>
  <figcaption>We are now able to use the email.</figcaption>
</figure>

Yes, there was no validation of the email on this form...actually it didn't
even need to be an email. At first, I wasn't sure of the utility of this
vulnerability - GitHub was escaping the output so no injection was possible. At
best you could list an in-use email address, as your address.

<figure style="text-align:center">
  <img src="/images/github/sarah-same-email.png"/>
  <figcaption>Both accounts now display the same public email.</figcaption>
</figure>

While I was busy looking for other bugs, I typed in my email into the search
bar, it was then that I realized that the vulnerability was slightly more
interesting than I had given it credit for.

<figure style="text-align:center">
  <img src="/images/github/endgame.png"/>
  <figcaption>Multiple Users with the Same Email.</figcaption>
</figure>

For those who haven't quite understood the risk here, GitHub summarized it
quite nicely in the writeup for the [GitHub Bug Bounty](https://bounty.GitHub.com/researchers/s-rah.html).

> This could have allowed an attacker to perform a social engineering attack by adding an email address to their profile that belonged to another user. When a user adds a collaborator to a repository they can find them by their username or their profile email address. As a result, by registering an email address of another user, an attacker may have been able to confuse the repository owner and have caused them to add the attacker’s account as a collaborator.

## Reporting the Vulnerabilty & Disclosure Timeline

I reported the issue to GitHub through their bounty site on the **17th November 2015**.

GitHub confirmed the issue on the **18th November 2015**.

On the **10th December 2015**, GitHub contacted me to confirm that they had fixed 
the vulnerability and that the report was eligible for their security bounty:

> Hello s-rah, <br/> The security team has had a chance to assess the severity and impact of the vulnerability you reported and we would like to offer you a $500 USD reward. We can also send you some GitHub swag and list your name on our Bug Bounty site. <br/> *snip*

They also gave me a coupon for 1 year on my current GitHub Plan. Thanks GitHub!

I asked GitHub to donate the bounty to [the Tor Project](https://www.torproject.org), which GitHub matched bringing the donation to **$1000!** - Again, **thanks GitHub!**

