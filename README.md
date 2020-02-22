![Combine Data Sources](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/combine-data-sources.png)

**CombineDataSources** provides custom Combine subscribers that act as table and collection view controllers and bind a stream of element collections to table or collection sections with cells.  

⚠️⚠️⚠️ **Note** 🚨🚨🚨: The package is currently work in progress.

### Table of Contents

1. [**Usage**](#usage)

1.1 [Bind a plain list of elements](https://github.com/combineopensource/CombineDataSources#bind-a-plain-list-of-elements)

1.2 [Bind a list of Section models](#bind-a-list-of-section-models)

1.2 [Customize the list controller](#customize-the-table-controller)

1.3 [List loaded in batches](#list-loaded-in-batches)

2. [**Installation**](#installation)

2.1 [Swift Package Manager](#swift-package-manager)

2.2 [Cocoapods](#cocoapods)

3. [**License**](#license)

4. [**Credits**](#credits)

---

## Usage

#### Demo App 📱

The repo contains a demo app in the *Example* sub-folder that demonstrates the different ways to use CombineDataSources in practice.

#### Bind a plain list of elements

```swift
var data = PassthroughSubject<[Person], Never>()

data
  .bind(subscriber: tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
  }))
  .store(in: &subscriptions)
```

![Plain list updates with CombineDataSources](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/plain-list.gif)

Respectively for a collection view:

```swift
data
  .bind(subscriber: collectionView.itemsSubscriber(cellIdentifier: "Cell", cellType: PersonCollectionCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
    cell.imageURL = URL(string: "https://api.adorable.io/avatars/100/\(model.name)")!
  }))
  .store(in: &subscriptions)
```

![Plain list updates for a collection view](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/plain-collection.gif)

#### Bind a list of Section models

```swift
var data = PassthroughSubject<[Section<Person>], Never>()

data
  .bind(subscriber: tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
  }))
  .store(in: &subscriptions)
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
  .bind(subscriber: tableView.sectionsSubscriber(controller))
  .store(in: &subscriptions)
```

#### List loaded in batches

A common pattern for list views is to load a very long list of elements in "batches" or "pages". (The distinction being that pages imply ordered, equal-length batches.)

**CombineDataSources** includes a data source allowing you to easily implement the batched list pattern called `BatchesDataSource` and a table view controller `TableViewBatchesController` which wraps loading items in batches via the said data source and managing your UI.

In case you want to implement your own custom logic, you can use directly the data source type:

```swift
let input = BatchesInput(
  reload: resetSubject.eraseToAnyPublisher(),
  loadNext: loadNextSubject.eraseToAnyPublisher()
)

let dataSource = BatchesDataSource<String>(
  items: ["Initial Element"],
  input: input,
  initialToken: nil,
  loadItemsWithToken: { token in
    return MockAPI.requestBatchCustomToken(token)
  })
```

`dataSource` is controlled via the two inputs:

- `input.reload` (to reload the very first batch) and 

- `loadNext` (to load each next batch) 
  
  The data source has four outputs: 

- `output.$items` is the current list of elements,

- `output.$isLoading` whether it's currently fetching a batch of elements, 

- `output.$isCompleted` whether the data source fetched all available elements, and 

- `output.$error` which is a stream of `Error?` elements where errors by the loading closure will bubble up.

In case you'd like to use the provided controller the code is fairly simple as well. You use the standard table view items controller and `TableViewBatchesController` like so:

```swift
let itemsController = TableViewItemsController<[[String]]>(cellIdentifier: "Cell", cellType: UITableViewCell.self, cellConfig: { cell, indexPath, text in
  cell.textLabel!.text = "\(indexPath.row+1). \(text)"
})

let tableController = TableViewBatchesController<String>(
  tableView: tableView,
  itemsController: itemsController,
  initialToken: nil,
  loadItemsWithToken: { nextToken in
    MockAPI.requestBatch(token: nextToken)
  }
)
```

`tableController` will set the table view data source, fetch items, and display cells with the proper animations.

## Todo

- [ ] much better README, pls
- [ ] use a @Published for the time being instead of withLatestFrom
- [ ] make the batches data source prepend or append the new batch (e.g. new items come from the top or at the bottom)
- [ ] cover every API with tests
- [ ] make the default batches view controller neater
- [ ] add AppKit version of the data sources
- [x] support Cocoapods

## Installation

### Swift Package Manager

Add the following dependency to your **Package.swift** file:

```swift
.package(url: "https://github.com/combineopensource/CombineDataSources, from: "0.2")
```

### Cocoapods
Add the following dependency to your **Podfile**:

```swift
pod 'CombineDataSources'
```

## License

CombineOpenSource is available under the MIT license. See the LICENSE file for more info.

## Combine Open Source

![Combine Slack channel](Assets/slack.png) 

CombineOpenSource Slack channel: [https://combineopensource.slack.com](https://combineopensource.slack.com). 

[Sign up here](https://join.slack.com/t/combineopensource/shared_invite/enQtNzQ1MzYyMTMxOTkxLWJkZmNkZDU4MTE4NmU2MjBhYzM5NzI1NTRlNWNhODFiMDEyMjVjOWZmZWI2NmViMzU3ZjZhYjc0YTExOGZmMDM)

## Credits

Created by Marin Todorov for [CombineOpenSource](https://github.com/combineopensource). 

📚 You can support me by checking out our Combine book: [combinebook.com](http://combinebook.com).

Inspired by [RxDataSources](https://github.com/RxSwiftCommunity/RxDataSources) and [RxRealmDataSources](https://github.com/RxSwiftCommunity/RxRealmDataSources).
