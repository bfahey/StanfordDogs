#  Loading and Displaying Dogs from an API

Learn how to use remote APIs with Core Data in the background to manage updating your user interface.

## Overview

This sample app shows a list of dog breeds and images from the Stanford Dogs Dataset using a third-party API and imports the data in the background. The user interface updates automatically through `NSFetchedResultsController` which observes changes to the persitent container's `viewContext`.

[Dog API](https://dog.ceo/dog-api/)
[Stanford Dogs Dataset](http://vision.stanford.edu/aditya86/ImageNetDogs/)
