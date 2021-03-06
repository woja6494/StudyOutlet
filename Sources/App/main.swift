// Imports
import Vapor
import VaporMySQL
import Auth
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Fluent
import Cookies
import Foundation

// Creating drop, adding mysql provider
let drop = Droplet()
try drop.addProvider(VaporMySQL.Provider.self)

// Add models
drop.preparations.append(Question.self)
drop.preparations.append(User.self)

// Custom cookie for session management
let auth = AuthMiddleware(user: User.self){ value in
    return Cookie(
        name: "alex_cookie",
        value: value,
        expires: Date().addingTimeInterval(60*60*5), // 1 minute
        secure: true,
        httpOnly: true
    )
}
drop.middleware.append(auth)

// For access token middleware
let protect = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))
let userController = UserController()
let questionController = QuestionConroller()
drop.group("api") { api in
    /*
     * Registration
     * Create a new Username and Password to receive an authorization token and account
     */
    api.post("register", handler: userController.register)
    
    /*
     * Log In
     * Pass the Username and Password to receive a new token
     */
    api.post("login", handler: userController.login)
    
    // Protected user endpoints
    api.group(BearerAuthenticationMiddleware(), protect) { user in
        user.get("users", handler: userController.getUsers)
    }
    // Protected question endpoints
    api.group(BearerAuthenticationMiddleware(), protect) { question in
        question.post("questions", handler: questionController.addQuestion)
        question.get("questions", handler: questionController.getQuestions)
    }
}

drop.run()
