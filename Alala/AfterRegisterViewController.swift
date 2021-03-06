//
//  AfterRegisterViewController.swift
//  Alala
//
//  Created by hoemoon on 14/06/2017.
//  Copyright © 2017 team-meteor. All rights reserved.
//

import UIKit

class AfterRegisterViewController: UIViewController {
  let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
  let userDataManager = UserDataManager.shared

  let profilePhoto = CircleImageView().then {
    $0.layer.borderWidth = 1
    $0.layer.masksToBounds = false
    $0.layer.borderColor = UIColor.lightGray.cgColor
    $0.isUserInteractionEnabled = true
  }
  let usernameTextField = UITextField().then {
    $0.borderStyle = .roundedRect
    $0.placeholder = "Type user name"
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
    $0.font = UIFont.systemFont(ofSize: 14)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.hidesBackButton = true
    self.navigationItem.rightBarButtonItem = doneButton
    doneButton.target = self
    doneButton.action = #selector(doneButtonDidTap)
    doneButton.isEnabled = false

    self.view.addSubview(profilePhoto)
    self.view.addSubview(usernameTextField)
    self.view.backgroundColor = UIColor.white

    profilePhoto.snp.makeConstraints { (make) in
      make.centerX.equalTo(self.view)
      make.centerY.equalTo(self.view).multipliedBy(0.7)
      make.width.equalTo(100)
      make.height.equalTo(100)
    }
    usernameTextField.snp.makeConstraints { (make) in
      make.centerX.equalTo(self.profilePhoto)
      make.top.equalTo(self.profilePhoto.snp.bottom).offset(50)
      make.width.equalTo(self.view).multipliedBy(0.6)
    }
    usernameTextField.addTarget(self, action: #selector(usernameFieldDidChange), for: .editingChanged)
    profilePhoto.addGestureRecognizer(UITapGestureRecognizer(
      target: self,
      action: #selector(AfterRegisterViewController.profilePhotoDidTap))
    )
  }

  func profilePhotoDidTap() {
    let pickerController = UIImagePickerController()
    pickerController.delegate = self
    self.present(pickerController, animated: true, completion: nil)
  }

  func doneButtonDidTap() {
    guard let profileImage = profilePhoto.image, let username = usernameTextField.text, !username.isEmpty else {
      return
    }
    var imageArray = [UIImage]()
    imageArray.append(profileImage)
    doneButton.isEnabled = false
    self.view.endEditing(true)
    SwiftSpinner.show("in progress...")
    MultipartNetworkManager.uploadMultipart(multiPartDataArray: imageArray, progressCompletion: nil) { (multipartIds) in
      self.userDataManager.updateProfileWithCloud(profileName: username, imageID: multipartIds[0], userInfo: nil, completion: { (success) in
        if success {
          SwiftSpinner.hide({
            self.userDataManager.getMeWithCloud(completion: { (user) in
              if user != nil {
                DispatchQueue.main.async {
                  NotificationCenter.default.post(name: .presentMainTabBar, object: nil)
                }
              }
            })
          })
        } else {
          print("failed update profile")
        }
      })
    }
  }

  func usernameFieldDidChange(_ textField: UITextField) {
    let profilename = textField.text!
    userDataManager.checkProfileNameUniqueWithCloud(profilename: profilename) { (isUnique) in
      if isUnique && !profilename.isEmpty {
        print("unique")
        self.doneButton.isEnabled = true
      } else {
        print("nonono")
        self.doneButton.isEnabled = false
      }
    }
  }
}

extension AfterRegisterViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
    self.profilePhoto.image = selectedImage
    self.profilePhoto.layer.borderColor = UIColor.clear.cgColor
    self.dismiss(animated: true, completion: nil)
  }
}

extension AfterRegisterViewController: UINavigationControllerDelegate {
}
