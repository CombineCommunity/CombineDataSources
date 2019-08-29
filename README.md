![Combine Data Sources](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/combine-data-sources.png)

**CombineDataSources** provides custom Combine subscribers that act as table and collection view controllers and bind a stream of element collections to table or collection sections with cells.  

⚠️⚠️⚠️ **Note**: The package is currently work in progress.

### Table of Contents

1. [**Usage**](#usage)

1.1 [Bind a plain list of elements](https://github.com/combineopensource/CombineDataSources#bind-a-plain-list-of-elements)

1.2 [Bind a list of Section models](#bind-a-list-of-section-models)

1.2 [Customize the table controller](#customize-the-table-controller)

1.3 [Subscribing a completing publisher](#subscribing-a-completing-publisher)

1.4 Batched/Paged list of elements

2. [**Installation**](#installation)

2.1 [Swift Package Manager](#swift-package-manager)

3. [**License**](#license)

4. [**Credits**](#credits)

---

## Usage

The repo contains a demo app in the *Example* sub-folder that demonstrates visually different ways to use CombineDataSources.

#### Bind a plain list of elements

```swift
var data = PassthroughSubject<[Person], Never>()

data
  .subscribe(subscriber: tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
  }))
```

![Plain list updates with CombineDataSources](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/plain-list.gif)

Respectively for a collection view:

```swift
data
  .subscribe(collectionView.itemsSubscriber(cellIdentifier: "Cell", cellType: PersonCollectionCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
    cell.imageURL = URL(string: "https://api.adorable.io/avatars/100/\(model.name)")!
  }))
```

![Plain list updates for a collection view](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/plain-collection.gif)

#### Bind a list of Section models

```swift
var data = PassthroughSubject<[Section<Person>], Never>()

data
  .subscribe(subscriber: tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
  }))
```

![Sectioned list updates with CombineDataSources](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/sections-list.gif)

#### Customize the table controller

```swift
var data = PassthroughSubject<[[Person]], Never>()

let controller = TableViewItemsController<[[Person]]>(cellIdentifier: "Cell", cellType: PersonCell.self) { cell, indexPath, person in
  cell.nameLabel.text = person.name
}
controller.animated = false

// More custom controller configuration ...

data
  .subscribe(subscriber: tableView.sectionsSubscriber(controller))
```

#### Subscribing a completing publisher

Sometimes you'll bind a publisher to your table or collection view and it will complete at a point. When you use `subscribe(_)` the completion event will release the CombineDataSource subscriber as well and that will likely render the table/collection empty.

In such case you can use the custom operator included in **CombineDataSources** `subscribe(retaining:)` that will give you an `AnyCancellable` to retain the subscriber, like so:

```swift
var subscriptions = [AnyCancellable]()
...
Just([Person(name: "test"])
  .subscribe(retaining: tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: UITableViewCell.self, cellConfig: { (cell, ip, person) in
    cell.textLabel!.text = person.name
  }))
  .store(in: &subscriptions)
```

This will keep the subscriber and the data source alive until you cancel the subscription manually or it is released from memory.

#### Batched/Paged list of elements

A common pattern in list based views is to load a very long list of elements in "batches" or "pages". (The distinction being that pages imply ordered, equal-length batches.)

**CombineDataSources** includes a data source allowing you to easily implement the batched list pattern called `BatchesDataSource`.

## Todo

- [ ] use a @Published for the time being instead of withLatestFrom
- [ ] make the batches data source prepend or append the new batch (e.g. new items come from the top or at the bottom)
- [ ] cover every API with tests
- [ ] make the default batches view controller neater
- [ ] add AppKit version of the data sources
- [ ] support Cocoapods

## Installation

### Swift Package Manager

Add the following dependency to your **Package.swift** file:

```swift
.package(url: "https://github.com/combineopensource/CombineDataSources, from: "0.2")
```

## License

CombineOpenSource is available under the MIT license. See the LICENSE file for more info.

## Credits

Created by Marin Todorov for [CombineOpenSource](https://github.com/combineopensource).

Inspired by [RxDataSources](https://github.com/RxSwiftCommunity/RxDataSources) and [RxRealmDataSources](https://github.com/RxSwiftCommunity/RxRealmDataSources).
