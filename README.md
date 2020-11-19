# VubHub - The unofficial vub app

<p float="left">
    <img src="/screenshots/Screenshots.png"/>
</p>

# I don't own an android device :(
There is no IOS build yet, however we did build a web application
that of course runs on any device. Now you can easily check your class schedules on your computer
too. Visit the [vubhub.me](http://vubhub.me) site to see for yourself.

# Info
This app hopes to make any VUB students life easier by concentrating all the information and VUB features into a single app.
VubHub currently supports an easy to read class schedule, news feed, partial Canvas functionality, a library seat registration
system and more, however that's not all because additional features are soon to come. If you like the idea and want to contribute
feel free to play around with the code and make some pull requests. If you are not a programmer, don't worry you can still
help us by just using the app and giving us feedback and new ideas. You can contact me (the lead developer) via the help
section in the app or by create an issue in this repository.

# How safe is this?
Safety is very important to us, so we want to be as transparent as possible in what
data we save.

This app is mainly build of two components. The canvas dependant functionality and the 
canvas independent functionality.

Let us begin with the canvas independent functionality. These are all the features like 
class schedule view, news feed, campus map etc. These do not depend on any personal information
(except the education you select). 

The other part, the canvas dependant functionality does not save more information then the 
actual real canvas app. We just save your 'canvas oauth2 token' which is basically your
login identity. This does not mean your password! We never even have your password because you
fill it into the canvas site directly (viewed through a webview in the app),
which then returns us a oauth2 token. On top of that, some data from canvas is cached
and saved to make the app a little smoother (name, user id, email, locale. See user.dart to view
the complete structure). **This data is still only saved on your device, we do not store
any data of you elsewhere. Making the canvas features perfectly safe.**

It is however perfectly possible to use the app without canvas if you choose to.

# Roadmap
- [x] Dark mode
- [ ] Message the user when their class schedule changes
- [x] Lecture filters
- [x] Periodic class schedule updates
- More canvas features
    - [x] Announcements
    - [x] Assignments
    - [x] Chat
    - [x] Modules
    - [x] Meetings
    - [x] Files
    - [x] External tools
    - [ ] Discussions
    - [ ] Syllabus
- [ ] Multiple interactive campus map's
- [ ] Further ~~desktop~~ web development
- [ ] 'Remind me about this lecture' feature
- [ ] More 'places' in the places tab, e.i. food places, free rooms etc.
- [ ] Additional student news section where students can share information
- [ ] Erasmus hoge school support
- [ ] Maybe ULB support
- [ ] NL locale
- [ ] A goddammed IOS build.

# Help me!
## I don't see any lectures
Check if you have selected the correct education type, faculty, education and groups. If there are
still no lectures, try the reload button on the top right. And if all else fails try to 
remove the app's stored data and retry.

## License 
GPL-3.0. See the LICENSE file for more information.