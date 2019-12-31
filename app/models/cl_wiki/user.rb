# frozen_string_literal: true

module ClWiki
  class User
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

    def self.users_root(*dirs)
      root = FileUtils.makedirs(::File.join($wiki_path, 'users'))
      ::File.join(root, dirs)
    end
  end
end
