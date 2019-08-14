# CombineDataSources

<p align="center">
<a href="https://github.com/apple/swift-package-manager" target="_blank"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="CombineDataSources supports Swift Package Manager (SPM)"></a> 
<img src="https://img.shields.io/badge/platforms-iOS%2013.0-333333.svg" />
</p>

**CombineDataSources** provides custom Combine subscribers that act as table and collection view controllers and bind a stream of element collections to table or collection sections with cells.  

**Note**: The package is currently work in progress.

## Usage

The repo contains a demo app in the *Example* sub-folder that demonstrates visually different ways to use CombineDataSources.

#### Bind a plain list of elements

```swift
var data = PassthroughSubject<[Person], Never>()

data
  .receive(subscriber: tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
    cell.nameLabel.text = model.name
  }))
```

![Plain list updates with CombineDataSources](https://github.com/combineopensource/CombineDataSources/raw/master/Assets/plain-list.gif)

#### Bind a list of Section models

```swift
var data = PassthroughSubject<[Section<Person>], Never>()

data
  .receive(subscriber: tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
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
  .receive(subscriber: tableView.sectionsSubscriber(controller))
```

