InfoStats
=========

A small library for iOS widget developers

(This description is nabbed directly from my Cydia repository)

 <p><br />This package allows widget developers (iWidget, WinterBoard) to query various things about the system, such as the battery state, or the amount of free RAM. Typically, such information is inaccessible via HTML/JavaScript, and so this is a fantatsic way of getting it. A Settings pane is included to turn off particular information from being generated, and does not require a respring.</p>
              <center><p><br /><strong>What can be accessed?</strong></p></center>
              <p>Battery: Current level, charging state</p>
              <p>RAM: Free RAM, used RAM, total usable RAM, and total physical RAM</p>
              <p>GPS: This is still in development!</p>
              <p>???</p>
              <center><p><br /><strong>Developers</strong></p>
              <p>The resulting information from this package can be accessed from /var/mobile/Library/Stats. Each set of information is saved into a .txt, so you'll only need to use jquery.get to grab it. During initial testing, it turns out that on some devices, iOS 6 caches the .txt file. In the ModMyi link below, there's a few examples of widgets that prevent that caching via ajax which allows them to correctly update.</p>
