let dim = 3

var valArray = [[Dictionary<String, Any>]]()
var initialRow = [Dictionary<String, Any>]()
for i in 0 ..< dim {
    initialRow.append(["currVal": 0, "poss": [], "group": 0])
}
for i in 0 ..< dim {
    valArray.append(initialRow)
}

valArray[0][0]["currVal"] = 4

valArray.map { print($0)}
