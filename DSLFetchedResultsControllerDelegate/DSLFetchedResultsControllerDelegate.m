/*
 DSLFetchedResultsControllerDelegate.m

 Copyright (c) 2013 Dative Studios. All rights reserved.
 Based on the work of Michael Fey's article:
 http://www.fruitstandsoftware.com/blog/2013/02/uitableview-and-nsfetchedresultscontroller-updates-done-right/

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DSLFetchedResultsControllerDelegate.h"


@interface DSLFetchedResultsControllerDelegate ()

@property (nonatomic, weak) id tableOrCollectionView;

@property (nonatomic, strong) NSMutableIndexSet *deletedSectionIndexes;
@property (nonatomic, strong) NSMutableIndexSet *insertedSectionIndexes;
@property (nonatomic, strong) NSMutableArray *deletedRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertedRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *updatedRowIndexPaths;

@end


@implementation DSLFetchedResultsControllerDelegate

- (id)initWithTableView:(UITableView*)tableView {
    self = [self init];
    if (self != nil) {
        _tableOrCollectionView = tableView;
        _sectionOffset = 0;
    }

    return self;
}

- (id)initWithCollectionView:(UICollectionView*)collectionView {
    self = [self init];
    if (self != nil) {
        _tableOrCollectionView = collectionView;
        _sectionOffset = 0;
    }

    return self;
}


#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // Prepare the collections for use
    self.insertedSectionIndexes = [NSMutableIndexSet indexSet];
    self.deletedSectionIndexes = [NSMutableIndexSet indexSet];
    self.deletedRowIndexPaths = [NSMutableArray array];
    self.insertedRowIndexPaths = [NSMutableArray array];
    self.updatedRowIndexPaths = [NSMutableArray array];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    indexPath = [self transposeIndexPath:indexPath];
    newIndexPath = [self transposeIndexPath:newIndexPath];

    // Record the changes so we can apply them in controllerDidChangeContent:
    switch (type) {
        case NSFetchedResultsChangeInsert:
            if (![self.insertedSectionIndexes containsIndex:newIndexPath.section]) {
                [self.insertedRowIndexPaths addObject:newIndexPath];
            }
            break;

        case NSFetchedResultsChangeDelete:
            if (![self.deletedSectionIndexes containsIndex:indexPath.section]) {
                [self.deletedRowIndexPaths addObject:indexPath];
            }
            break;

        case NSFetchedResultsChangeMove:
            if (![self.insertedSectionIndexes containsIndex:newIndexPath.section]) {
                [self.insertedRowIndexPaths addObject:newIndexPath];
            }

            if (![self.deletedSectionIndexes containsIndex:indexPath.section]) {
                [self.deletedRowIndexPaths addObject:indexPath];
            }
            break;

        case NSFetchedResultsChangeUpdate:
            if ([self shouldUpdateRowForObject:anObject]) {
                [self.updatedRowIndexPaths addObject:indexPath];
            }
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    sectionIndex += self.sectionOffset;
    
    // Record the changes so we can apply them in controllerDidChangeContent:
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.insertedSectionIndexes addIndex:sectionIndex];
            break;

        case NSFetchedResultsChangeDelete:
            [self.deletedSectionIndexes addIndex:sectionIndex];
            break;

        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    BOOL hasChanges = (self.insertedRowIndexPaths.count > 0 || self.deletedSectionIndexes.count > 0 || self.deletedRowIndexPaths.count > 0 || self.insertedRowIndexPaths > 0 || self.updatedRowIndexPaths.count > 0);

    if (hasChanges) {
        if ([self.delegate respondsToSelector:@selector(fetchedResultsControllerDelegateWillUpdateContent:)]) {
            [self.delegate fetchedResultsControllerDelegateWillUpdateContent:self];
        }

        // Apply the changes to whatever control we have
        if ([self.tableOrCollectionView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = self.tableOrCollectionView;
            [tableView beginUpdates];

            [tableView deleteSections:self.deletedSectionIndexes withRowAnimation:[self sectionAnimationForChangeType:DSLFetchedResultsControllerDelegateDelete]];
            [tableView insertSections:self.insertedSectionIndexes withRowAnimation:[self sectionAnimationForChangeType:DSLFetchedResultsControllerDelegateInsert]];

            [tableView deleteRowsAtIndexPaths:self.deletedRowIndexPaths withRowAnimation:[self rowAnimationForChangeType:DSLFetchedResultsControllerDelegateDelete]];
            [tableView insertRowsAtIndexPaths:self.insertedRowIndexPaths withRowAnimation:[self rowAnimationForChangeType:DSLFetchedResultsControllerDelegateInsert]];
            [tableView reloadRowsAtIndexPaths:self.updatedRowIndexPaths withRowAnimation:[self rowAnimationForChangeType:DSLFetchedResultsControllerDelegateUpdate]];

            [tableView endUpdates];
        }
        else if ([self.tableOrCollectionView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = self.tableOrCollectionView;

            [collectionView performBatchUpdates:^{
                [collectionView deleteSections:self.deletedSectionIndexes];
                [collectionView insertSections:self.insertedSectionIndexes];

                [collectionView deleteItemsAtIndexPaths:self.deletedRowIndexPaths];
                [collectionView insertItemsAtIndexPaths:self.insertedRowIndexPaths];
                [collectionView reloadItemsAtIndexPaths:self.updatedRowIndexPaths];
            } completion:^(BOOL finished) {}];
        }

        if ([self.delegate respondsToSelector:@selector(fetchedResultsControllerDelegateDidUpdateContent:)]) {
            [self.delegate fetchedResultsControllerDelegateDidUpdateContent:self];
        }
    }

    // Nil out the collections now we're done
    self.insertedSectionIndexes = nil;
    self.deletedSectionIndexes = nil;
    self.deletedRowIndexPaths = nil;
    self.insertedRowIndexPaths = nil;
    self.updatedRowIndexPaths = nil;
}


#pragma mark Delegate calling methods

- (UITableViewRowAnimation)rowAnimationForChangeType:(DSLFetchedResultsControllerDelegateChangeType)changeType {
    UITableViewRowAnimation animation = UITableViewRowAnimationAutomatic;

    if ([self.delegate respondsToSelector:@selector(fetchedResultsControllerDelegate:rowAnimationForChangeType:)]) {
        animation = [self.delegate fetchedResultsControllerDelegate:self rowAnimationForChangeType:changeType];
    }

    return animation;
}

- (UITableViewRowAnimation)sectionAnimationForChangeType:(DSLFetchedResultsControllerDelegateChangeType)changeType {
    UITableViewRowAnimation animation = UITableViewRowAnimationAutomatic;

    if ([self.delegate respondsToSelector:@selector(fetchedResultsControllerDelegate:sectionAnimationForChangeType:)]) {
        animation = [self.delegate fetchedResultsControllerDelegate:self sectionAnimationForChangeType:changeType];
    }

    return animation;
}

- (BOOL)shouldUpdateRowForObject:(id)anObject {
    BOOL shouldUpdate = YES;

    if ([self.delegate respondsToSelector:@selector(fetchedResultsControllerDelegate:shouldUpdateRowForObject:)]) {
        shouldUpdate = [self.delegate fetchedResultsControllerDelegate:self shouldUpdateRowForObject:anObject];
    }

    return shouldUpdate;
}


#pragma mark 

- (NSIndexPath*)transposeIndexPath:(NSIndexPath*)indexPath {
    return [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section + self.sectionOffset];
}

@end
