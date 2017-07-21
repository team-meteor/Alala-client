//
//  FeedViewController.swift
//  Alala
//
//  Created by hoemoon on 05/06/2017.
//  Copyright © 2017 team-meteor. All rights reserved.
//

import UIKit
import IGListKit
import Alamofire

class FeedViewController: UIViewController {

  fileprivate let cameraButton = UIBarButtonItem(
    image: UIImage(named: "camera")?.resizeImage(scaledTolength: 25),
    style: .plain,
    target: nil,
    action: nil
  )

  fileprivate let messageButton = UIBarButtonItem(
    image: UIImage(named: "send")?.resizeImage(scaledTolength: 25),
    style: .plain,
    target: nil,
    action: nil
  )

  fileprivate var posts: [Post] = []
  fileprivate var nextPage: Int?
  fileprivate var isLoading: Bool = false

  fileprivate let refreshControl = UIRefreshControl()

  let collectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout()
    let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    view.backgroundColor = UIColor.white
    return view
  }()

  lazy var adapter: ListAdapter = {
    return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
  }()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.tabBarItem.image = UIImage(named: "feed")?.resizeImage(scaledTolength: 25)
    self.tabBarItem.selectedImage = UIImage(named: "feed-selected")?.resizeImage(scaledTolength: 25)
    self.tabBarItem.imageInsets.top = 5
    self.tabBarItem.imageInsets.bottom = -5
    self.navigationItem.leftBarButtonItem = cameraButton
    self.navigationItem.rightBarButtonItem = messageButton
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(preparePosting), name: .preparePosting, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(postDidCreate), name: .postDidCreate, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(postDidLike), name: .postDidLike, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(postDidUnlike), name: .postDidUnlike, object: nil)
    self.navigationItem.titleView = UILabel().then {
      $0.font = UIFont(name: "IowanOldStyle-BoldItalic", size: 20)
      $0.text = "Alala"
      $0.sizeToFit()
    }
    self.fetchFeed(paging: .refresh)
    adapter.collectionView = collectionView
    adapter.dataSource = self
    view.addSubview(collectionView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.collectionView.frame = view.bounds
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.isNavigationBarHidden = false
  }

  fileprivate func fetchFeed(paging: Paging) {
    guard !self.isLoading else { return }
    self.isLoading = true

    FeedService.feed(paging: paging) { [weak self] response in
      guard let `self` = self else { return }
      self.refreshControl.endRefreshing()
      self.isLoading = false

      switch response.result {
      case .success(let feed):
        let newPosts = feed.posts ?? []
        switch paging {
        case .refresh:
          self.posts = newPosts
        case .next:
          self.posts.append(contentsOf: newPosts)
        }
        self.nextPage = feed.nextPage

        DispatchQueue.main.async {
          self.adapter.performUpdates(animated: true, completion: nil)
        }
      case .failure(let error):
        print(error)
      }
    }
  }

  func postDidCreate(_ notification: Notification) {
    guard let post = notification.userInfo?["post"] as? Post else { return }
    self.posts.insert(post, at: 0)
    self.adapter.performUpdates(animated: true, completion: nil)
  }

  func preparePosting(_ notification: Notification) {
    self.moveToFeedViewController()

    guard let postDic = notification.userInfo?["postDic"] as? [String:Any] else { return }
    guard let multipartArr = postDic["multipartArr"] as? [Any] else { return }
    guard let message = postDic["message"] as? String? else { return }

    self.getMultipartsIdArr(multipartArr: multipartArr) { idArr in

      PostService.postWithMultipart(idArr: idArr, message: message, progress: nil, completion: { [weak self] response in
        guard self != nil else { return }
        switch response.result {
        case .success(let post):
          NotificationCenter.default.post(
            name: .postDidCreate,
            object: self,
            userInfo: ["post": post]
          )
        case .failure(let error):
          print(error)

        }}
      )}
  }

  func getMultipartsIdArr(multipartArr: [Any], completion: @escaping (_ idArr: [String]) -> Void) {

    var counter = 0
    var multipartsIdArr = [String]()

    for multipart in multipartArr {
      let progressView = UIProgressView()
      progressView.backgroundColor = UIColor.yellow
      progressView.frame = CGRect(
        x: 0,
        y: (self.navigationController?.navigationBar.frame.height)! + 50 * CGFloat(counter),
        width: self.view.bounds.width,
        height: 50)
      self.collectionView.addSubview(progressView)
      progressView.progress = 0.0
      progressView.isHidden = false
      counter += 1

      MultipartService.uploadMultipart(multiPartData: multipart, progressCompletion: { percent in
        progressView.setProgress(percent, animated: true)
      }) { imageId in
        multipartsIdArr.append(imageId)
        progressView.isHidden = true
        if multipartsIdArr.count == multipartArr.count {
          completion(multipartsIdArr)

        }
      }
    }
  }

  /**
   * TabBarViewController중 피드 화면으로 이동
   *
   * - Note : 포스트를 업로드할 때는 무조건 피드VC로 이동되어야 함
   */
  func moveToFeedViewController() {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let tabBarVC = appDelegate.window?.rootViewController as! MainTabBarController
    if tabBarVC.selectedViewController != self {
      tabBarVC.selectedIndex = 0
    }
  }

  func postDidLike(_ notification: Notification) {
    guard let postID = notification.userInfo?["postID"] as? String else { return }
    for i in 0..<self.posts.count {
      let post = self.posts[i]
      if post.id == postID {
        post.likeCount! += 1
        post.isLiked = true
        self.posts[i] = post

        self.collectionView.reloadData()
        //self.adapter.performUpdates(animated: true, completion: nil)
        break
      }
    }
  }

  func postDidUnlike(_ notification: Notification) {
    guard let postID = notification.userInfo?["postID"] as? String else { return }
    for i in 0..<self.posts.count {
      let post = self.posts[i]
      if post.id == postID {
        post.likeCount = max(0, post.likeCount - 1)
        post.isLiked = false
        self.posts[i] = post
        self.collectionView.reloadData()
        //self.adapter.performUpdates(animated: true, completion: nil)
        break
      }
    }
  }
}

extension FeedViewController: ListAdapterDataSource {
  func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
    let items: [ListDiffable] = self.posts

    return items
  }
  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    if object is Post {
      return PostSectionController()
    } else {
      return ListSectionController()
    }
  }
  func emptyView(for listAdapter: ListAdapter) -> UIView? {
    return nil
  }
}

extension FeedViewController: InteractiveButtonGroupCellDelegate {
  func commentButtondidTap(_ post: Post) {
    guard let comments = post.comments else { return }
    self.navigationController?.pushViewController(CommentViewController(comments: comments), animated: true)
  }
}
