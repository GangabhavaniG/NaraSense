class User < ApplicationRecord
  devise :database_authenticatable,
         :jwt_authenticatable,
         :registerable,
         :validatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null
end