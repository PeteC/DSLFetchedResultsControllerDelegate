DSLFetchedResultsControllerDelegate
===================================

A simple class to take the chore out of implementing NSFetchedResultsControllerDelegates.


# Usage

Firstly, create an instance of a DSLFetchedResultsControllerDelegate, passing the UITableView or UICollectionView that you'd like to keep up-to-date with the contents of an NSFetchedResultsController:

```Objective-C
self.myFRCDelegate = [[DSLFetchedResultsControllerDelegate alloc] initWithCollectionView:self.collectionView];
```

Then the NSFetchedResultsController's delegate to be your DSLFetchedResultsControllerDelegate object:

```Objective-C
self.myFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
self.myFRC.delegate = self.myFRCDelegate;
```

Your table or collection view will now be automatically updated in response to changes in the NSFetchedResultsController's content.

# Optional delegate

DSLFetchedResultsControllerDelegate has it's own optional delegate to allow you to tailor it's behaviour and respond to changes in content


```Objective-C
- (BOOL)fetchedResultsControllerDelegate:(DSLFetchedResultsControllerDelegate*)delegate
              shouldUpdateRowAtIndexPath:(NSIndexPath*)indexPath;
```
Use this method to prevent updating an object's row or cell. You may want to do this if, for example, the properties that have changed don't warrant an update (by inspecting the object's changedValuesForCurrentEvent)

.

```Objective-C
- (UITableViewRowAnimation)fetchedResultsControllerDelegate:(DSLFetchedResultsControllerDelegate*)delegate 
                              sectionAnimationForChangeType:(DSLFetchedResultsControllerDelegateChangeType)changeType;
- (UITableViewRowAnimation)fetchedResultsControllerDelegate:(DSLFetchedResultsControllerDelegate*)delegate 
                                  rowAnimationForChangeType:(DSLFetchedResultsControllerDelegateChangeType)changeType;
```
Use these methods to specify the animation style to use when updating a row or section. By default, DSLFetchedResultsControllerDelegate uses UITableViewRowAnimationAutomatic.

.

```Objective-C
- (void)fetchedResultsControllerDelegateWillUpdateContent:(DSLFetchedResultsControllerDelegate*)delegate;
- (void)fetchedResultsControllerDelegateDidUpdateContent:(DSLFetchedResultsControllerDelegate*)delegate;
```
These methods are called before and after a DSLFetchedResultsControllerDelegate updates it's table or collection view.


# Credit

The original version of this class was based on the workarounds documented by [Michael Fey](https://github.com/MrRooni)'s article "[UITableview and NSFetchedResultsController updates done right](http://www.fruitstandsoftware.com/blog/2013/02/uitableview-and-nsfetchedresultscontroller-updates-done-right/)".
