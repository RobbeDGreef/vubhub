# Yet to implement:
- Last updated information in app drawer
- Robuster crawler (fix the infinite recursion danger etc etc)
- Selecting which lectures you actually want to show up in your lecture view
- Clickable class items to see all details and directions to get there
- lesson counter
- Library quick book email field should check if the email is valid
- Settings email field should check if the email is valid
- YOOOOOOOOOOOOOOOOOOO canvas has AN API yesssssssssssssss this saves me a TONN of web scraping
- Add timeout to loading symbol 
- Add reservations tab where you can see your reservations and even cancel them
- autoupdate system
- check free spaces in infogroup etc
- Add support for campus jette ? (places, and map)
- Add support for erasmus (they have a different lecture system (via google sheets),
places, map)
- Lock up the crawler so that multiple requests cannot happen simultaneously because
that will mess up the super delicate server connection 
- Notify user if their lectures have changed
- Access their uploaded files from canvas ?
- Just integrate most of canvas into the app ?
- Make proper map view, (select multiple maps for different campuses)
- Draw own vub maps so that we can mark rooms on that map
- "Get to campus" info (delijn, nmbs etc)
- Redo UI of library reserve view because it's crap
- in fact we need to theme and fix the UI of this whole app because its not very pretty
- Create help field to send email to the developers with potential bugs or features 
- only show loading throbber in lecture view if data is actually being fetched from the web not from the cache
- setting to send notifications every time a lecture is starting 
- maybe setting to push notification x amount of time before the first lecture of the day
- deadlines van taken
- Swipe to change bottom nav bar tab
- Move bottom nav bar body into page view https://stackoverflow.com/questions/49781227/flutter-update-bottomnavigationbar
- Instead of always passing around infohandler references just make it global.

- Firebase messaging (project already build, just have to integrate some stuff)
- https://pub.dev/packages/flutter_local_notifications but I still have to figure out
  if we want to use this one (i think we do because this would prevent us from routing
  everything through the server idk)

- Keep canvas data in cache and connect lecturelist to actual lectures

## Canvas API specific
- Implement oAuth2 flow see: https://canvas.instructure.com/doc/api/file.oauth.html in settings
    for now i have a user generated token check development/ (this note is only for myself since development/ folder is not synced with git)


# Done
- Bug in week calculating system.
- stop duplicate rotationsystems from being printed
- save groups to multiple seperate files 
- load multiple groups
- load the previously selected education correctly
- update the selected groups correctly
- update lecture view on group change 
- Long tap on detail card in lecture details copies text
- In the lecture details remove details tabs that are empty
- add a "no classes today" text if there are no classes today
- Loading symbol while loading various things
- Campus map
- Bottom tabs for various new tabs
    - classes tab
    - campus map tab
    - reserve space in library
- Reserve space in places like the library
- Make map view not infinitely zoomable
- Bug: Library seat viewer does not show unavailable seats in text filter search
- Bug: when app opens it show "no classes today" even if there are
- Library seat expanded view
- add dates to library booking

# Concrete roadmap starting from 17/10
- More extensive canvas support
    - [ ] Actual canvas login (auto fill in the users group etc as well)
        - [-] Steal panopto access token? (PROBABLY ILLEGAL)
            Did some research and the only way to get the access code is to
            decrypt it with panopto's client key, which of course, we do not have.
            This makes sense because otherwise it would be a very insecure connection
            but it does suck for us.
        - [ ] Implement proper oAuth2 flow (Need a client key from the VUB)

    - [ ] View extensive assignment information
    - [ ] View announcements
    - [ ] Star important announcements
    - [ ] Quick view unread (and maybe starred) announcements from all lectures
    - [ ] Cache canvas lecture data into memory (and storage) 
    - [ ] Connect the lecture view to the cached lectures so when you click a lecture you can view more information about the lecture in general.

- LectureView
    - [ ] View due assignments in the lectureview
    - [ ] Filtering lecture view

- Notification support
    - [ ] Send notification on lecture changes
    - [ ] Remind user of assignments that are not turned in.
    - [ ] Give user capability to 'remind me' about when lectures start (not so important)

- Easier campus life (not so important now that we go into code red)
    - [ ] Interactive campus map
        - [ ] Show lecture locations
    - [ ] View current food possibilities
        - [ ] VUB resto food possibilities
        - [ ] Third party food places
    - [ ] (Book) sporting stuff like swimming pool
    - [ ] View currently unused classrooms
    - [ ] 'Get to campus' information, delijn, nmbs, ... information

- Student life
    - [ ] View friends class schedule 

- Backend fixes
    - [ ] Server to send push notifications
    - [ ] Rebuster crawler
    - [ ] Code cleanup
    - [ ] Code documentation
    - [ ] Write the readme and code of conduct

- Small fixes
    - [ ] Swipe to change tabs
    - [ ] Move help into app drawer
