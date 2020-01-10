# frozen_string_literal: true

module ClWiki
  class User < ClWiki::UserBase
    include ActiveModel::SecurePassword
    include ActiveModel::Serializers::JSON

    has_secure_password

    attr_accessor :username, :password_digest

    validates :username, presence: true

    def attributes
      {username: self.username,
       password_digest: self.password_digest}
    end

    def attributes=(hash)
      hash.each do |key, value|
        send("#{key}=", value)
      end
    end

    def self.create(username, password)
      self.new.tap do |u|
        u.username = username
        u.password = password
        u.save
      end
    end

    def self.find(username)
      user_file = users_root("#{username}.json")
      if ::File.exist?(user_file)
        user = self.new
        json = ::File.read(user_file)
        user.from_json(json)
      end
    end

    def save
      ::File.open(User.users_root("#{username}.json"), 'w') do |f|
        # as_json yields a Hash for some reason, which then can't be parsed
        # when read from disk.
        f.write(self.attributes.to_json)
      end
    end

    def self.users_root(filename)
      root = FileUtils.makedirs(::File.join($wiki_conf.wiki_path, 'users'))
      ::File.join(root, filename)
    end

    # Generate a consistent key that can be used with Lockbox for encrypting
    # content, and that is not persisted anywhere.
    def derive_encryption_key(password)
      if authenticate(password)
        pass = 'secret'
        salt = 'static salt' # so the same key is derived each time
        iter = 10_000
        hash = OpenSSL::Digest::SHA256.new
        len = hash.digest_length
        OpenSSL::KDF.pbkdf2_hmac(pass,
                                 salt: salt,
                                 iterations: iter,
                                 length: len,
                                 hash: hash)
      else
        raise 'Could not authenticate password'
      end
    end

    def encryption_key
      @encryption_key
    end

    # Never, never, persist this! It needs to be pushed in from the session
    # store, for usage down deeper in the ClWiki `lib` code.
    def cached_encryption_key=(value)
      @encryption_key = value
    end

    def name
      self.username
    end
  end
end
