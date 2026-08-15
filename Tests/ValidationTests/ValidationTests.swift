import Testing
import Validation

@Suite
struct ValidationTests {
    @Test
    func validate() throws {
        let user = User(
            name: "Tanner",
            age: 23,
            pet: Pet(name: "Zizek Pulaski", age: 4),
            preferedColors: ["blue?", "green?"]
        )
        user.luckyNumber = 7
        user.email = "tanner@vapor.codes"
        try user.validate()
        try user.pet.validate()

        let secondUser = User(
            name: "Natan",
            age: 30,
            pet: Pet(name: "Nina", age: 4),
            preferedColors: ["pink"]
        )
        secondUser.profilePictureURL = "https://www.somedomain.com/somePath.png"
        secondUser.email = "natan@vapor.codes"
        try secondUser.validate()
    }

    @Test
    func ascii() throws {
        try Validator<String>.ascii.validate("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        try Validator<String>.ascii.validate("\n\r\t")
        #expect(throws: (any Error).self) { try Validator<String>.ascii.validate("\n\r\t\u{129}") }
        try Validator<String>.ascii.validate(" !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
        #expect(throws: (any Error).self) {
            try Validator<String>.ascii
                .validate("ABCDEFGHIJKLMNOPQR🤠STUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        }
    }

    @Test
    func alphanumeric() throws {
        try Validator<String>.alphanumeric
            .validate("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        #expect(throws: (any Error).self) {
            try Validator<String>.alphanumeric
                .validate("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        }
    }

    @Test
    func empty() throws {
        try Validator<String>.empty.validate("")
        #expect(throws: (any Error).self) { try Validator<String>.empty.validate("something") }
        try Validator<[Int]>.empty.validate([])
        #expect(throws: (any Error).self) { try Validator<[Int]>.empty.validate([1, 2]) }
    }

    @Test
    func email() throws {
        try Validator<String>.email.validate("tanner@vapor.codes")
        #expect(throws: (any Error).self) {
            try Validator<String>.email.validate("tanner@vapor.codestanner@vapor.codes")
        }
        #expect(throws: (any Error).self) { try Validator<String>.email.validate("tanner@vapor.codes.") }
        #expect(throws: (any Error).self) { try Validator<String>.email.validate("tanner@@vapor.codes") }
        #expect(throws: (any Error).self) { try Validator<String>.email.validate("@vapor.codes") }
        #expect(throws: (any Error).self) { try Validator<String>.email.validate("tanner@codes") }
        #expect(throws: (any Error).self) { try Validator<String>.email.validate("asdf") }
    }

    @Test
    func range() throws {
        try Validator<Int>.range(-5 ... 5).validate(4)
        try Validator<Int>.range(-5 ... 5).validate(5)
        try Validator<Int>.range(-5 ... 5).validate(-5)
        let tooHigh = #expect(throws: (any Error).self) { try Validator<Int>.range(-5 ... 5).validate(6) }
        #expect((tooHigh as? any ValidationError)?.reason == "data is greater than 5")
        let tooLow = #expect(throws: (any Error).self) { try Validator<Int>.range(-5 ... 5).validate(-6) }
        #expect((tooLow as? any ValidationError)?.reason == "data is less than -5")

        try Validator<Int>.range(5...).validate(.max)

        try Validator<Int>.range(-5 ..< 6).validate(-5)
        try Validator<Int>.range(-5 ..< 6).validate(-4)
        try Validator<Int>.range(-5 ..< 6).validate(5)
        #expect(throws: (any Error).self) { try Validator<Int>.range(-5 ..< 6).validate(-6) }
        #expect(throws: (any Error).self) { try Validator<Int>.range(-5 ..< 6).validate(6) }
    }

    @Test
    func countCharacters() throws {
        let validator = Validator<String>.count(1 ... 6)
        try validator.validate("1")
        try validator.validate("123")
        try validator.validate("123456")
        let tooShort = #expect(throws: (any Error).self) { try validator.validate("") }
        #expect((tooShort as? any ValidationError)?
            .reason == "data is less than required minimum of 1 character")
        let tooLong = #expect(throws: (any Error).self) { try validator.validate("1234567") }
        #expect((tooLong as? any ValidationError)?
            .reason == "data is greater than required maximum of 6 characters")
    }

    @Test
    func countItems() throws {
        let validator = Validator<[Int]>.count(1 ... 6)
        try validator.validate([1])
        try validator.validate([1, 2, 3])
        try validator.validate([1, 2, 3, 4, 5, 6])
        let tooShort = #expect(throws: (any Error).self) { try validator.validate([]) }
        #expect((tooShort as? any ValidationError)?.reason == "data is less than required minimum of 1 item")
        let tooLong = #expect(throws: (any Error).self) { try validator.validate([1, 2, 3, 4, 5, 6, 7]) }
        #expect((tooLong as? any ValidationError)?
            .reason == "data is greater than required maximum of 6 items")
    }

    @Test
    func url() throws {
        try Validator<String>.url.validate("https://www.somedomain.com/somepath.png")
        try Validator<String>.url.validate("https://www.somedomain.com/")
        try Validator<String>.url.validate("file:///Users/vapor/rocks/somePath.png")
        #expect(throws: (any Error).self) { try Validator<String>.url.validate("www.somedomain.com/") }
        #expect(throws: (any Error).self) { try Validator<String>.url.validate("bananas") }
    }
}

final class User: Validatable, Reflectable, Codable, @unchecked Sendable {
    var id: Int?
    var name: String
    var age: Int
    var email: String?
    var pet: Pet
    var luckyNumber: Int?
    var profilePictureURL: String?
    var preferedColors: [String]

    init(id: Int? = nil, name: String, age: Int, pet: Pet, preferedColors: [String] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.pet = pet
        self.preferedColors = preferedColors
    }

    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        // validate name is at least 5 characters and alphanumeric
        try validations.add(\.name, .count(5...) && .alphanumeric)
        // validate age is 18 or older
        try validations.add(\.age, .range(18...))
        // validate the email is valid and is not nil
        try validations.add(\.email, !.nil && .email)
        try validations.add(\.email, .email && !.nil) // test other way
        // validate the email is valid or is nil
        try validations.add(\.email, .nil || .email)
        try validations.add(\.email, .email || .nil) // test other way
        // validate that the lucky number is nil or is 5 or 7
        try validations.add(\.luckyNumber, .nil || .in(5, 7))
        // validate that the profile picture is nil or a valid URL
        try validations.add(\.profilePictureURL, .url || .nil)
        try validations.add(\.preferedColors, !.empty)
        return validations
    }
}

final class Pet: Codable, Validatable, Reflectable, @unchecked Sendable {
    var name: String
    var age: Int
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }

    static func validations() throws -> Validations<Pet> {
        var validations = Validations(Pet.self)
        try validations.add(\.name, .count(5...) && .characterSet(.alphanumerics + .whitespaces))
        try validations.add(\.age, .range(3...))
        return validations
    }
}
