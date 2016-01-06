<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
  <link rel="apple-touch-icon" sizes="57x57" href="/apple-touch-icon.png" />
  <link rel="apple-touch-icon" sizes="114x114" href="/apple-touch-icon.png" />
  <link rel="apple-touch-icon" sizes="72x72" href="/apple-touch-icon-144.png" />
  <link rel="apple-touch-icon" sizes="144x144" href="/apple-touch-icon-144.png" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="robots" content="noarchive,noodp,noydir" />
  <meta name="referrer" content="always" />
  <meta name="theme-color" content="#AC130D" />
  <link rel="shortcut icon" href="/favicon.ico" />
  <title>Example News</title>
  <link href="/assets/select2.self.css?body=1" media="all" rel="stylesheet" />
<link href="/assets/application.self.css?body=1" media="all" rel="stylesheet" />
<link href="/assets/mobile.self.css?body=1" media="all" rel="stylesheet" />
    <script src="/assets/jquery.self.js?body=1"></script>
<script src="/assets/jquery_ujs.self.js?body=1"></script>
<script src="/assets/autosize.self.js?body=1"></script>
<script src="/assets/jquery_class.self.js?body=1"></script>
<script src="/assets/select2.self.js?body=1"></script>
<script src="/assets/application.self.js?body=1"></script>
    <script>
      Lobsters.curUser = '1';
    </script>
  
</head>
<body>
  <div id="wrapper">
    <div id="header">
      <div id="headerleft">
        <a id="l_holder" style="background-color: #390000;" href="/"
        title="Example News (Current traffic: 1)"></a>





        <span class="headerlinks">
            <a href="/" >Home</a>
            <a href="/recent" >Recent</a>
            <a href="/comments" >Comments</a>
            <a href="/threads" >Your Threads</a>
            <a href="/stories/new" >Submit Story</a>
            <a href="/search" >Search</a>
        </span>
      </div>

      <div id="headerright">
        <span class="headerlinks">
        <a href="/filters" >Filters</a>
            <a href="/messages" >Messages</a>

          <a href="/settings" >test
            (0)</a>

          <a data-confirm="Are you sure you want to logout?" data-method="post" href="/logout" rel="nofollow">Logout</a>
        </span>
      </div>

      <div class="clear"></div>
    </div>

    <div id="inside">

      <div class="box wide">
  <div class="legend">
    Request an Invitation
  </div>

  <p>
  If you don't know (or can't find) an <a href="/u/">existing user</a> from
  whom to request an invitation, you can make a public request for one.  This
  will display your name and memo to all other logged-in users who can then
  send you an invitation if they recognize you.
  </p>

  <p>
  Your e-mail address must be valid and confirmed by visiting a URL e-mailed to
  you before your request will be displayed.  Your e-mail address will not be
  shown to any other users (except moderators).
  </p>

  <form accept-charset="UTF-8" action="/invitations/create_by_request" class="new_invitation_request" id="new_invitation_request" method="post"><div style="display:none"><input name="utf8" type="hidden" value="&#x2713;" /></div>
    <p>
    <label for="invitation_request_name">Name:</label>
    <input id="invitation_request_name" name="invitation_request[name]" size="30" type="text" />
    <br />

    <label for="invitation_request_email">E-mail Address:</label>
    <input id="invitation_request_email" name="invitation_request[email]" size="30" type="text" />
    <br />

    <label for="invitation_request_memo">URL:</label>
    <input id="invitation_request_memo" name="invitation_request[memo]" size="30" type="text" />
    <br />
    <label></label>
    <span class="na">URL to verify you (Personal website, Github account,
      etc.)</span>
    </p>

    <p>
    <input name="commit" type="submit" value="Request Invitation" />
    </p>
</form></div>


      <div id="footer">
        <a href="/moderations">Moderation Log</a>
        <a href="/chat">Chat</a>
        <a href="/privacy">Privacy</a>
        <a href="/about">About</a>
      </div>
      <div class="clear"></div>
    </div>
  </div>
</body>
</html>
