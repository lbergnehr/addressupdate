# AddressUpdate

Update addresses in Address Book.app / Contacts.app automatically based on phone numbers.

Old project that I thought should be up here in case someone wants to take a look.

## AddressUpdate Application
Application that will monitor changes to the Mac OS X Address Book (Contacts.app) in newer versions. Whenever such a change occurs, it will use its configured sites to look for an address using the phone number of that contact.

## AddressUpdate Address Book Plug-In
Instead of monitoring the address book all the time there is also an Address Book Plug-In which essentially creates a context menu for phone numbers in the Address Book which can be used to fetch the address for that particular phone number and contact.

## Known problems
* The plug-in stopped working with 64 bit version of Address Book.
