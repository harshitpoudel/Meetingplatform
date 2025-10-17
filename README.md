# meetingplatform

A new Flutter project.

## Getting Started
## Meeting Platform (Flutter + Firebase Emulator Suite)

A cross-platform **meeting scheduling app  built with Flutter and Firebase.  
Users can:
- View other registered users
- Send and receive invitations
- Accept / reject invitations
- Automatically schedule meetings when accepted
- View meetings in a list or on a calendar
- Seed demo users, invitations, and meetings for instant testing

## ✨ Features

- **Authentication**
  - Email/password login (or random account if left blank)
  - Auto-registers on first login
  - Logout supported

- **Users Page**
  - Browse all users
  - Invite another user to a meeting
  - Seed demo data (adds Alice, Bob, sample invites & meetings)
  - Open calendar
  - Logout

- **Invitations Page**
  - Tabs for **Received** and **Sent**
  - Accept → creates a scheduled meeting
  - Reject/Delete → removes the invitation

- **Meetings Page**
  - Lists all your meetings
  - Shows participants’ names & emails
  - Shows scheduled time
  - Delete to cancel a meeting

- **Calendar Page**
  - Monthly view of meetings
  - Markers on days with events
  - Tap a day → view participants in bottom sheet

---

## 🛠 Tech Stack

- **Framework:** Flutter
- **Backend:** Firebase (Auth + Firestore)
- **Local Setup:** Firebase Emulator Suite
- **State Management:** Riverpod
- **UI:** Material 3 + TableCalendar

---

## ⚡ Setup Instructions

git clone https://github.com/harshitpoudel/meetingplatform.git
cd meetingplatform
flutter pub get
2. Firebase Emulator
This project runs completely locally with the Firebase Emulator Suite.

Start emulators:

firebase emulators:start --project demo-meeting

By default: they are set to

Auth Emulator → 127.0.0.1:9099

Firestore Emulator → 127.0.0.1:8080

Emulator UI → http://127.0.0.1:4000/

Running the App on
Web

flutter run -d chrome
Opens the app in your browser.

Android Emulator
Open Android Studio → Tools → Device Manager → Launch an emulator (e.g. Pixel 6).

In terminal:
flutter devices
flutter run -d emulator-5554
(replace emulator-5554 with the ID from flutter devices).

iOS Simulator (macOS only)
open -a Simulator
flutter run -d "iPhone 15 Pro" 


How to Use

Security Notes **donot use your own private credentials**
Running locally → Emulator defaults to allow all reads/writes uses random data for now 
so you dont have to login just press login when login page pops up

Steps by step instruction on how to use the app

## Loginpage

- Login kepp the username and password blank for now and press login 

- First login auto-registers. and keeps you in the database

## Homepage

- Home Page shows all the users that are there which has been added

- Invite others invite can be sent by pressing invite button which can be seen in the invite page which can be deleted if mind changed

- Seed demo data option is placed at the top right which seeds sample invites & meetings

- Calendar to view accepted meetings and view the date

- Logout to sign out

## Invitations Page

- Received tab → Accept or Reject allows user to accept or reject invite

-Sent tab → View and delete your outgoing invites

## Meetings Page

- See all meetings you’re part of

- Cancel with button

## Calendar Page

See meetings on a calendar

Tap a date → view participants


For production: configure firestore.rules

Demo Workflow
Start emulators:

firebase emulators:start --project demo-meeting

## Run app in Chrome:

flutter run -d chrome on the terminal 

follows same steps as above for web too

Login (blank → random user)

On Users Page, click Seed demo data

Switch to Invitations Page → Accept/Reject

Check Meetings Page + Calendar Page

logout


Ideas for Improvement

Google Sign-In / proper Auth

Time picker for meeting scheduling

Push notifications for new invites

Avatars + improved UI polish

Firestore security rules

Unit & integration tests

not much though they could have been done

