//
//  SSAuthenticationBaseViewController.swift
//  SS_Authentication
//
//  Created by Eddie Li on 25/05/16.
//  Copyright © 2016 Software and Support Media GmbH. All rights reserved.
//

import UIKit
import Validator
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class SSAuthenticationBaseViewController: UIViewController, SSAuthenticationNavigationBarDelegate, UITextFieldDelegate {
    var navigationBar: SSAuthenticationNavigationBar?
    fileprivate var loadingView: SSAuthenticationLoadingView?
    
    var hideStatusBar = false
    var isEmailValid = false
    var isPasswordValid = false
    var isConfirmPasswordValid = false
    
    var statusBarStyle: UIStatusBarStyle = .default
    var navigationBarColor = UIColor.white
    
    fileprivate var hasLoadedConstraints = false

    // MARK: - Initialisation
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    deinit {
        self.emailTextField.validateOnEditingEnd(validationEnabled: false)
        self.passwordTextField.validateOnEditingEnd(validationEnabled: false)
        self.confirmPasswordTextField.validateOnEditingEnd(validationEnabled: false)
        
        self.emailTextField.delegate = nil
        self.passwordTextField.delegate = nil
        self.confirmPasswordTextField.delegate = nil
    }
    
    // MARK: - Accessors
    
    fileprivate(set) lazy var resourceBundle: Bundle = {
        let bundleURL = Bundle(for: SSAuthenticationBaseViewController.self).resourceURL
        let _resourceBundle = Bundle(url: bundleURL!)
        return _resourceBundle!
    }()
    
    fileprivate(set) lazy var emailTextField: UITextField = {
        let _emailTextField = UITextField()
        _emailTextField.delegate = self
        _emailTextField.keyboardType = .emailAddress
        _emailTextField.spellCheckingType = .no
        _emailTextField.autocorrectionType = .no
        _emailTextField.autocapitalizationType = .none
        _emailTextField.attributedPlaceholder = NSAttributedString(string: self.localizedString(key: "user.email"), attributes: FONT_ATTR_MEDIUM_LIGHT_GRAY)
        _emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        _emailTextField.leftViewMode = .always
        _emailTextField.layer.borderColor = UIColor.gray.cgColor
        _emailTextField.layer.borderWidth = 1.0
        _emailTextField.font = FONT_MEDIUM
        _emailTextField.textColor = FONT_COLOUR_BLACK
        var rules = ValidationRuleSet<String>()
        let emailRule = ValidationRulePattern(pattern: .EmailAddress, failureError: ValidationError(message: self.localizedString(key: "emailFormatError.message")))
        rules.add(rule: emailRule)
        _emailTextField.validationRules = rules
        _emailTextField.validationHandler = { result in
            self.isEmailValid = result.isValid
        }
        _emailTextField.validateOnEditingEnd(validationEnabled: true)
        return _emailTextField
    }()
    
    fileprivate(set) lazy var passwordTextField: UITextField = {
        let _passwordTextField = UITextField()
        _passwordTextField.delegate = self
        _passwordTextField.spellCheckingType = .no
        _passwordTextField.autocorrectionType = .no
        _passwordTextField.autocapitalizationType = .none
        _passwordTextField.isSecureTextEntry = true
        _passwordTextField.clearsOnBeginEditing = true
        _passwordTextField.attributedPlaceholder = NSAttributedString(string: self.localizedString(key: "user.password"), attributes: FONT_ATTR_MEDIUM_LIGHT_GRAY)
        _passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        _passwordTextField.leftViewMode = .always
        _passwordTextField.layer.borderColor = UIColor.gray.cgColor
        _passwordTextField.layer.borderWidth = 1.0
        _passwordTextField.font = FONT_MEDIUM
        _passwordTextField.textColor = FONT_COLOUR_BLACK
        var rules = ValidationRuleSet<String>()
        let passwordRule = ValidationRulePattern(pattern: PASSWORD_VALIDATION_REGEX, failureError: ValidationError(message: self.localizedString(key: "passwordValidFail.message")))
        rules.add(rule: passwordRule)
        _passwordTextField.validationRules = rules
        _passwordTextField.validationHandler = { result in
            self.isPasswordValid = result.isValid
        }
        _passwordTextField.validateOnEditingEnd(validationEnabled: true)
        return _passwordTextField
    }()

    fileprivate(set) lazy var confirmPasswordTextField: UITextField = {
        let _confirmPasswordTextField = UITextField()
        _confirmPasswordTextField.delegate = self
        _confirmPasswordTextField.spellCheckingType = .no
        _confirmPasswordTextField.autocorrectionType = .no
        _confirmPasswordTextField.autocapitalizationType = .none
        _confirmPasswordTextField.isSecureTextEntry = true
        _confirmPasswordTextField.clearsOnBeginEditing = true
        _confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: self.localizedString(key: "user.confirmPassword"), attributes: FONT_ATTR_MEDIUM_LIGHT_GRAY)
        _confirmPasswordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        _confirmPasswordTextField.leftViewMode = .always
        _confirmPasswordTextField.layer.borderColor = UIColor.gray.cgColor
        _confirmPasswordTextField.layer.borderWidth = 1.0
        _confirmPasswordTextField.font = FONT_MEDIUM
        _confirmPasswordTextField.textColor = FONT_COLOUR_BLACK
        var rules = ValidationRuleSet<String>()
        let confirmPasswordRule = ValidationRuleEquality(dynamicTarget: { return self.passwordTextField.text ?? "" }, failureError: ValidationError(message: self.localizedString(key: "passwordNotMatchError.message")))
        rules.add(rule: confirmPasswordRule)
        _confirmPasswordTextField.validationRules = rules
        _confirmPasswordTextField.validationHandler = { result in
            self.isConfirmPasswordValid = result.isValid
        }
        _confirmPasswordTextField.validateOnEditingEnd(validationEnabled: true)
        return _confirmPasswordTextField
    }()

    open lazy var emailFailureAlertController: UIAlertController = {
        let _emailFailureAlertController = UIAlertController(title: nil, message: self.localizedString(key: "emailFormatError.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: self.localizedString(key: "cancelButtonTitle"), style: .cancel, handler: { (action) in
            self.emailTextField.becomeFirstResponder()
        })
        _emailFailureAlertController.addAction(cancelAction)
        return _emailFailureAlertController
    }()
    
    open lazy var passwordValidFailAlertController: UIAlertController = {
        let _passwordValidFailAlertController = UIAlertController(title: nil, message: self.localizedString(key: "passwordValidFail.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: self.localizedString(key: "cancelButtonTitle"), style: .cancel, handler: { (action) in
            self.passwordTextField.text = nil
            self.passwordTextField.becomeFirstResponder()
        })
        _passwordValidFailAlertController.addAction(cancelAction)
        return _passwordValidFailAlertController
    }()

    open lazy var confirmPasswordValidFailAlertController: UIAlertController = {
        let _confirmPasswordValidFailAlertController = UIAlertController(title: nil, message: self.localizedString(key: "passwordNotMatchError.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: self.localizedString(key: "cancelButtonTitle"), style: .cancel, handler: { (action) in
            self.confirmPasswordTextField.text = nil
            self.confirmPasswordTextField.becomeFirstResponder()
        })
        _confirmPasswordValidFailAlertController.addAction(cancelAction)
        return _confirmPasswordValidFailAlertController
    }()

    fileprivate(set) lazy var noInternetAlertController: UIAlertController = {
        let _noInternetAlertController = UIAlertController(title: nil, message: self.localizedString(key: "noInternetConnectionError.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: self.localizedString(key: "cancelButtonTitle"), style: .cancel, handler: { (action) in
            
        })
        _noInternetAlertController.addAction(cancelAction)
        return _noInternetAlertController
    }()

    // MARK: - Implementation of SSAuthenticationNavigationBarDelegate protocols
    
    func skip() {
        
    }
    
    func back() {
        self.emailTextField.delegate = nil
        self.passwordTextField.delegate = nil
        self.confirmPasswordTextField.delegate = nil
        
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Implementation of UITextFieldDelegate protocols
    
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.gray.cgColor
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.text?.characters.count > 0) {
            if (textField == self.emailTextField) {
                if (!self.isEmailValid) {
                    textField.layer.borderColor = UIColor.red.cgColor
                    self.present(self.emailFailureAlertController, animated: true, completion: nil)
                }
            } else if (textField == self.passwordTextField) {
                if (!self.isPasswordValid) {
                    textField.layer.borderColor = UIColor.red.cgColor
                    self.present(self.passwordValidFailAlertController, animated: true, completion: nil)
                }
            } else if (textField == self.confirmPasswordTextField) {
                if (!self.isConfirmPasswordValid) {
                    textField.layer.borderColor = UIColor.red.cgColor
                    self.present(self.confirmPasswordValidFailAlertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
    
    // MARK: - Public Methods
    
    func setup() {
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func showLoadingView() {
        self.view.bringSubview(toFront: self.loadingView!)
        UIView.animate(withDuration: ANIMATION_DURATION, animations: {
            self.loadingView?.alpha = 1.0
        }) 
    }
    
    func hideLoadingView() {
        UIView.animate(withDuration: ANIMATION_DURATION, animations: {
            self.loadingView?.alpha = 0.0
        }) 
    }
    
    func localizedString(key: String) -> String {
        return self.resourceBundle.localizedString(forKey: key, value: nil, table: "SS_Authentication")
    }
    
    open func forceUpdateStatusBarStyle(_ style: UIStatusBarStyle) {
        self.statusBarStyle = style
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    open func updateNavigationBarColor(_ color: UIColor) {
        self.navigationBarColor = color
    }
    
    // MARK: - Subviews
    
    fileprivate func setupNavigationBar() {
        self.navigationBar = SSAuthenticationNavigationBar()
        self.navigationBar?.delegate = self
        self.navigationBar?.skipButton?.setAttributedTitle(NSAttributedString(string: self.localizedString(key: "user.skip"), attributes: FONT_ATTR_XLARGE_WHITE), for: UIControlState())
        self.navigationBar?.backgroundColor = self.navigationBarColor
    }
    
    fileprivate func setupLoadingView() {
        self.loadingView = SSAuthenticationLoadingView()
        self.loadingView?.alpha = 0.0
    }
    
    func setupSubviews() {
        self.setupLoadingView()
        self.loadingView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.loadingView!)
        
        self.setupNavigationBar()
        self.navigationBar?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.navigationBar!)
    }
    
    override open var prefersStatusBarHidden : Bool {
        return self.hideStatusBar
    }
    
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return self.statusBarStyle
    }
    
    override open func updateViewConstraints() {
        if (!self.hasLoadedConstraints) {
            let views = ["loading": self.loadingView!,
                         "bar": self.navigationBar!] as [String : Any]
            
            let metrics = ["BAR_HEIGHT": NAVIGATION_BAR_HEIGHT]
            
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[loading]", options: .directionMask, metrics: nil, views: views))

            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[bar]|", options: .directionMask, metrics: nil, views: views))

            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[loading]", options: .directionMask, metrics: nil, views: views))

            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[bar(BAR_HEIGHT)]", options: .directionMask, metrics: metrics, views: views))

            self.view.addConstraint(NSLayoutConstraint(item: self.loadingView!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0.0))

            self.view.addConstraint(NSLayoutConstraint(item: self.loadingView!, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0.0))

            self.hasLoadedConstraints = true
        }
        super.updateViewConstraints()
    }
    
    // MARK: - View lifecycle
    
    override open func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor.white
        self.view.translatesAutoresizingMaskIntoConstraints = true
        
        self.setupSubviews()
        self.updateViewConstraints()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }
        
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.confirmPasswordTextField.delegate = self
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.emailTextField.delegate = nil
        self.passwordTextField.delegate = nil
        self.confirmPasswordTextField.delegate = nil
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
