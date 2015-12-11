# Having Fun with Github Email Settings

This is the story of a small vulnerability in Github. It all started
when I was playing around on github one evening.

<blockquote class="twitter-tweet tw-align-center" lang="en"><p lang="en" dir="ltr">Thanks to <a href="https://twitter.com/SarahJamieLewis">@SarahJamieLewis</a> for reporting an issue with profile email addresses and her donation to <a href="https://twitter.com/torproject">@torproject</a>. <a href="https://t.co/TgqcV5LLje">https://t.co/TgqcV5LLje</a></p>&mdash; GitHub Security (@GitHubSecurity) <a href="https://twitter.com/GitHubSecurity/status/675047561401647105">December 10, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

Github is very careful about emails - if you try to add another email to
your account, and that email is already associated with an account - you will
receive an error:

<figure style="text-align:center">
  <img src="/images/github/email-error.png"/>
  <figcaption>Github won't allow you to add an email that already exists</figcaption>
</figure>

This is for good reason. Github allows users to add other users to private
organizations and repositories by their email address, as such, the 
email settings screen does not allow you to add an email address that belongs
to another user.

However, there is another screen which allows you to set emails, the *Edit Profile*
page. The Github UI will only let you select emails which already exist in
your email screen.

However, should you simply construct the PUT request yourself, with an email
that you want to use...

<figure style="text-align:center">
  <img src="/images/github/emailselect.png"/>
  <figcaption>We are now able to use the email.</figcaption>
</figure>

Yes, there was no validation of the email on this form...actually it didn't
even need to be an email. At first, I wasn't sure of the utility of this
vulnerability - Github was escaping the output so no injection was possible. At
best you could list an in-use email address, as your address.

<figure style="text-align:center">
  <img src="/images/github/sarah-same-email.png"/>
  <figcaption>Both accounts now display the same public email.</figcaption>
</figure>

While I was busy looking for other bugs, I typed in my email into the search
bar, it was then that I realised that the vulnerability was slightly more
interesting than I had given it credit for.

<figure style="text-align:center">
  <img src="/images/github/endgame.png"/>
  <figcaption>Multiple Users with the Same Email.</figcaption>
</figure>

For those who haven't quite understood the risk here, Github summarized it
quite nicely in the writeup for the [Github Bug Bounty](https://bounty.github.com/researchers/s-rah.html).

> This could have allowed an attacker to perform a social engineering attack by adding an email address to their profile that belonged to another user. When a user adds a collaborator to a repository they can find them by their username or their profile email address. As a result, by registering an email address of another user, an attacker may have been able to confuse the repository owner and have caused them to add the attacker’s account as a collaborator.

## Reporting the Vulnerabilty & Disclosure Timeline

I reported the issue to github through their bounty site on the **17th November 2015**.

Github confirmed the issue on the **18th November 2015**.

On the **10th December 2015**, Github contacted me to confirm that they had fixed 
the vulnerability and that the report was eligible for their security bounty:

> Hello s-rah, <br/> The security team has had a chance to assess the severity and impact of the vulnerability you reported and we would like to offer you a $500 USD reward. We can also send you some GitHub swag and list your name on our Bug Bounty site. <br/> *snip*

They also gave me a coupon for 1 year on my current Github Plan. Thanks Github!

I asked Github to donate the bounty to [the Tor Project](https://tor-project.org), which Github matched bringing the donation to **$1000!** - Again, **thanks Github!**

