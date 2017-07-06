//
//  PersonalViewController.swift
//  Alala
//
//  Created by hoemoon on 05/06/2017.
//  Copyright © 2017 team-meteor. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper

/**

 */
class PersonalViewController: UIViewController, PersonalInfoViewDelegate, NoContentsViewDelegate, UICollectionViewDataSource {

  // MARK: - UI Objects
  let discoverPeopleButton = UIBarButtonItem(
    image: UIImage(named: "add_user")?.resizeImage(scaledTolength: 25),
    style: .plain,
    target: self,
    action: #selector(PersonalViewController.discoverPeopleButtonTap)
  )

  let archiveButton = UIBarButtonItem(
    image: UIImage(named: "personal")?.resizeImage(scaledTolength: 25),
    style: .plain,
    target: nil,
    action: nil
  )

  let scrollView = UIScrollView().then {
    $0.showsHorizontalScrollIndicator = false
    $0.showsVerticalScrollIndicator = true
    $0.bounces = true
  }
  let cellReuseIdentifier = "gridCell"

  let personalInfoView = PersonalInfoView()

  let noContentsGuideView = NoContentsView()

//  let postGridCollectionView = UICollectionView().then {
//    $0.showsHorizontalScrollIndicator = false
//    $0.showsVerticalScrollIndicator = false
//    $0.backgroundColor = .white
//    $0.alwaysBounceVertical = true
//    $0.register(PostGridCell.self, forCellWithReuseIdentifier: "gridCell")
//  }

  let postGridCollectionView: UICollectionView = {
    let columnLayout = ColumnFlowLayout(
      cellsPerRow: 3,
      minimumInteritemSpacing: 1,
      minimumLineSpacing: 1,
      sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    )
    let view = UICollectionView(frame: .zero, collectionViewLayout: columnLayout)
    view.register(PostGridCell.self, forCellWithReuseIdentifier: "gridCell")
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    view.backgroundColor = UIColor.white
    return view
  }()
  //let postCollectionView = UICollectionView()

//  var myUserInfo = User()

  // MARK: - Initialize
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    self.tabBarItem.image = UIImage(named: "personal")?.resizeImage(scaledTolength: 25)
    self.tabBarItem.selectedImage = UIImage(named: "personal-selected")?.resizeImage(scaledTolength: 25)
    self.tabBarItem.imageInsets.top = 5
    self.tabBarItem.imageInsets.bottom = -5

    self.navigationItem.leftBarButtonItem = discoverPeopleButton
    self.navigationItem.rightBarButtonItem = archiveButton
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationItem.titleView = UILabel().then {
      $0.font = UIFont(name: "HelveticaNeue", size: 20)
      $0.text = "User ID"
      $0.sizeToFit()
    }
    self.navigationController?.navigationBar.topItem?.title = ""

    self.view.addSubview(scrollView)
    scrollView.snp.makeConstraints { (make) in
      make.top.equalTo(self.view)
      make.left.equalTo(self.view)
      make.right.equalTo(self.view)
      make.bottom.equalTo(self.view)
    }

    //-- Section 1 : closable notice view (Optional)
    // (todo)

    //-- Section 2 : personal infomation view (Required)
    scrollView.addSubview(personalInfoView)
    personalInfoView.snp.makeConstraints { (make) in
      make.top.equalTo(scrollView)
      make.left.equalTo(scrollView)
      make.right.equalTo(scrollView)
      //make.bottom.equalTo(personalInfoView.profileNameLabel.snp.bottom).offset(10)
      make.bottom.equalTo(personalInfoView.subMenuBar.snp.bottom)
      make.width.equalTo(scrollView)
    }
    personalInfoView.delegate = self

    //-- Section 3 : personal post list or no contents view (one of both)

    if(false) { // TODO
      scrollView.addSubview(noContentsGuideView)
      noContentsGuideView.snp.makeConstraints { (make) in
        make.top.equalTo(personalInfoView.snp.bottom)
        make.left.equalTo(scrollView)
        make.right.equalTo(scrollView)
        //make.bottom.equalTo(scrollView)
        make.bottom.equalTo(self.view.snp.bottom)
      }
      noContentsGuideView.delegate = self
    } else {
      scrollView.addSubview(postGridCollectionView)
      postGridCollectionView.snp.makeConstraints { (make) in
        make.top.equalTo(personalInfoView.snp.bottom)
        make.left.equalTo(scrollView)
        make.right.equalTo(scrollView)
        make.bottom.equalTo(self.view.snp.bottom)
      }
      postGridCollectionView.dataSource = self
      postGridCollectionView.isScrollEnabled = false
    }
    personalInfoView.setupUserInfo(userInfo: AuthService.instance.currentUser!)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.isNavigationBarHidden = false
  }

  // MARK: - PersonalInfoViewDelegate
  func discoverPeopleButtonTap() {
    let sampleVC = DiscoverPeopleViewController()
    self.navigationController?.pushViewController(sampleVC, animated: true)
  }

  func postsAreaTap() {
//    let size = CGSize(width: scrollView.frame.size.width, height: scrollView.bounds.size.height)
//    scrollView.contentSize = size
    var moveRect = scrollView.frame
    moveRect.origin.y = personalInfoView.frame.size.height + 64

    scrollView.setContentOffset(moveRect.origin, animated: true)
  }

  func followersAreaTap() {
    let followerVC = FollowViewController(type:.follower)
    self.navigationController?.pushViewController(followerVC, animated: true)
  }

  func followingAreaTap() {
    let followingVC = FollowViewController(type:.following)
    self.navigationController?.pushViewController(followingVC, animated: true)
  }

  func editProfileButtonTap(sender: UIButton) {
    let editProfileVC = UINavigationController(rootViewController: EditProfileViewController())
    self.present(editProfileVC, animated: true, completion: nil)
  }

  func optionsButtonTap(sender: UIButton) {
    let optionsVC = OptionsViewController()
    self.navigationController?.pushViewController(optionsVC, animated: true)
  }

  func gridPostMenuButtonTap(sender: UIButton) {

  }

  func listPostMenuButtonTap(sender: UIButton) {

  }

  func photosForYouMenuButtonTap(sender: UIButton) {
    let photosVC = PhotosForYouViewController()
    self.navigationController?.pushViewController(photosVC, animated: true)
  }

  func savedMenuButtonTap(sender: UIButton) {
    let savedVC = SavedViewController()
    self.navigationController?.pushViewController(savedVC, animated: true)
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

    //personalInfoView.bounds.size.height

    let size = CGSize(width: scrollView.frame.size.width, height: scrollView.bounds.size.height)
    scrollView.contentSize = size

    return 10
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell: PostGridCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! PostGridCell
    cell.backgroundColor = UIColor.red
    return cell
  }

  // MARK: - NoContentsViewDelegate
  /**
   * 내가 작성한 포스트가 없을 경우 노출되는 NoContentsView에서 'Share your first photo or video' 버튼을 선택했을 때 발생하는 delegate
   */
  func addContentButtonTap(sender: UIButton) {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let tabBarVC = appDelegate.window?.rootViewController as! MainTabBarController
    tabBarVC.presentWrapperViewController()
  }

  /*
  func logoutButtonDidTap() {
    AuthService.instance.logout { (success) in
      if success {
        NotificationCenter.default.post(name: .presentLogin, object: nil, userInfo: nil)
      } else {

      }
    }
  }
 */
}

class ColumnFlowLayout: UICollectionViewFlowLayout {

  let cellsPerRow: Int
  override var itemSize: CGSize {
    get {
      guard let collectionView = collectionView else { return super.itemSize }
      let marginsAndInsets = sectionInset.left + sectionInset.right + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
      let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
      return CGSize(width: itemWidth, height: itemWidth)
    }
    set {
      super.itemSize = newValue
    }
  }

  init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
    self.cellsPerRow = cellsPerRow
    super.init()

    self.minimumInteritemSpacing = minimumInteritemSpacing
    self.minimumLineSpacing = minimumLineSpacing
    self.sectionInset = sectionInset
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
    let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
    context.invalidateFlowLayoutDelegateMetrics = newBounds != collectionView?.bounds
    return context
  }
}
