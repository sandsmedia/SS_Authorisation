//
//  SSAuthenticationResetPasswordViewController.swift
//  SS_Authentication
//
//  Created by Eddie Li on 25/05/16.
//  Copyright © 2016 Software and Support Media GmbH. All rights reserved.
//

import UIKit

protocol SSAuthenticationResetDelegate: class {
    func resetSuccess()
}

class SSAuthenticationResetPasswordViewController: SSAuthenticationBaseViewController {
    weak var delegate: SSAuthenticationResetDelegate?
    
    fileprivate var resetButton: UIButton?

    fileprivate var hasLoadedConstraints = false

    // MARK: - Initialisation
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    deinit {
        self.delegate = nil
    }
    
    // MARK: - Accessors
    
    fileprivate(set) lazy var forgotPasswordSuccessAlertController: UIAlertController = {
        let _forgotPasswordSuccessAlertController = UIAlertController(title: nil, message: self.localizedString(key: "forgot_password_success.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: self.localizedString(key: "ok.title"), style: .cancel, handler: { (action) in
            let _ = self.navigationController?.popViewController(animated: true)
        })
        _forgotPasswordSuccessAlertController.addAction(cancelAction)
        return _forgotPasswordSuccessAlertController
    }()

    fileprivate(set) lazy var forgotPasswordFailedAlertController: UIAlertController = {
        let _forgotPasswordFailedAlertController = UIAlertController(title: nil, message: self.localizedString(key: "forgot_password_fail.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: self.localizedString(key: "ok.title"), style: .cancel, handler: { (action) in
            self.emailTextField.becomeFirstResponder()
        })
        _forgotPasswordFailedAlertController.addAction(cancelAction)
        return _forgotPasswordFailedAlertController
    }()

    // MARK: - Events
    
    func resetButtonAction() {
        self.tapAction()
        guard (self.isEmailValid) else {
            if (!self.emailFailureAlertController.isBeingPresented) {
                self.emailTextField.layer.borderColor = UIColor.red.cgColor
                self.present(self.emailFailureAlertController, animated: true, completion: nil)
            }
            return
        }

        if let email = self.emailTextField.text {
            self.resetButton?.isUserInteractionEnabled = false
            self.showLoadingView()
            
            let userDict = [EMAIL_KEY: email]
            SSAuthenticationManager.sharedInstance.reset(userDictionary: userDict) { (user: SSUser?, statusCode: Int, error: Error?) in
                if (user != nil) {
                    self.present(self.forgotPasswordSuccessAlertController, animated: true, completion: nil)
                    self.delegate?.resetSuccess()
                } else {
                    self.present(self.forgotPasswordFailedAlertController, animated: true, completion: nil)
                }
                self.hideLoadingView()
                self.resetButton?.isUserInteractionEnabled = true
            }
        }
    }
    
    func tapAction() {
        for textField in (self.textFieldsStackView?.arrangedSubviews)! {
            textField.resignFirstResponder()
        }
    }
    
    // MARK: - Public Methods
    
    override internal func forceUpdateStatusBarStyle(_ style: UIStatusBarStyle) {
        super.forceUpdateStatusBarStyle(style)
    }
    
    override internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.resetButtonAction()
        return super.textFieldShouldReturn(textField)
    }

    // MARK: - Subviews
    
    fileprivate func setupResetButton() {
        self.resetButton = UIButton(type: .system)
        self.resetButton?.backgroundColor = SSAuthenticationManager.sharedInstance.buttonBackgroundColour
        self.resetButton?.setAttributedTitle(NSAttributedString.init(string: self.localizedString(key: "user.restore"), attributes: SSAuthenticationManager.sharedInstance.buttonFontAttribute), for: UIControlState())
        self.resetButton?.addTarget(self, action: .resetButtonAction, for: .touchUpInside)
        self.resetButton?.layer.cornerRadius = GENERAL_ITEM_RADIUS
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        self.emailTextField.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldsStackView?.addArrangedSubview(self.emailTextField)

        self.setupResetButton()
        self.resetButton?.translatesAutoresizingMaskIntoConstraints = false
        self.buttonsStackView?.addArrangedSubview(self.resetButton!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: .tapAction)
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func updateViewConstraints() {
        if (!self.hasLoadedConstraints) {
            let views: [String: Any] = ["email": self.emailTextField,
                                        "reset": self.resetButton!]
            
            let metrics = ["SPACING": GENERAL_SPACING,
                           "LARGE_SPACING": LARGE_SPACING,
                           "WIDTH": GENERAL_ITEM_WIDTH,
                           "HEIGHT": ((IS_IPHONE_4S) ? (GENERAL_ITEM_HEIGHT - 10.0) : GENERAL_ITEM_HEIGHT),
                           "BUTTON_HEIGHT": GENERAL_ITEM_HEIGHT]
            
            self.textFieldsStackView!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(LARGE_SPACING)-[email]-(LARGE_SPACING)-|", options: .directionMask, metrics: metrics, views: views))

            self.textFieldsStackView!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[email(HEIGHT)]", options: .directionMask, metrics: metrics, views: views))

            self.buttonsStackView!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(LARGE_SPACING)-[reset]-(LARGE_SPACING)-|", options: .directionMask, metrics: metrics, views: views))
            
            self.buttonsStackView!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[reset(BUTTON_HEIGHT)]", options: .directionMask, metrics: metrics, views: views))

            self.hasLoadedConstraints = true
        }
        super.updateViewConstraints()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let top = self.topLayoutGuide.length
        let bottom = self.bottomLayoutGuide.length
        self.baseScrollView?.contentInset = UIEdgeInsetsMake(top, 0.0, bottom, 0.0)
    }

    // MARK: - View lifecycle
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.localizedString(key: "user.restore")
        self.emailTextField.returnKeyType = .go
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.emailTextField.becomeFirstResponder()
    }
}

private extension Selector {
    static let resetButtonAction = #selector(SSAuthenticationResetPasswordViewController.resetButtonAction)
    static let tapAction = #selector(SSAuthenticationResetPasswordViewController.tapAction)
}
