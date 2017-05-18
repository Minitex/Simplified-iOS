import Foundation

@objc protocol BookDetailTableViewDelegate {
  func reportProblemTapped()
  func relatedWorksTapped()
  func exportCitationTapped()
  var book: NYPLBook { get }
}

class NYPLBookDetailTableView: UITableView {
  
  override init(frame: CGRect, style: UITableViewStyle) {
    super.init(frame: frame, style: style)
    self.isScrollEnabled = false
    self.backgroundColor = UIColor.clear
    self.layoutMargins = UIEdgeInsetsMake(self.layoutMargins.top,
                                          self.layoutMargins.left+12,
                                          self.layoutMargins.bottom,
                                          self.layoutMargins.right+12)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public var intrinsicContentSize: CGSize {
    get {
      layoutIfNeeded()
      return CGSize(width: UIViewNoIntrinsicMetric, height: contentSize.height)
    }
  }
}

class NYPLBookDetailTableViewDelegate: NSObject, UITableViewDelegate, UITableViewDataSource {
  
  var viewDelegate: BookDetailTableViewDelegate!
  var cells: [BookDetailCellType]!
  
  init (withDelegate viewDelegate: BookDetailTableViewDelegate) {
    self.viewDelegate = viewDelegate
    cells = [.relatedWorks, .citations]
    if (viewDelegate.book.acquisition.report != nil) {
      cells.append(BookDetailCellType.reportAProblem)
    }
  }
  
  enum BookDetailCellType: String {
    case relatedWorks = "Related Works"
    case reportAProblem = "Report a Problem"
    case citations = "Export Citation"
  }
  

  
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cells.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.accessoryType = .disclosureIndicator
    cell.backgroundColor = UIColor.clear
    cell.textLabel?.font = UIFont.customFont(forTextStyle: .body)
    let cellType = cells[indexPath.row] as BookDetailCellType
    cell.textLabel?.text = cellType.rawValue
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch (cells[indexPath.row] as BookDetailCellType) {
    case .relatedWorks:
      viewDelegate.relatedWorksTapped()
    case .reportAProblem:
      viewDelegate.reportProblemTapped()
    case .citations:
      viewDelegate.exportCitationTapped()
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
}
