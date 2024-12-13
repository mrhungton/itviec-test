
# == Schema Information
# User (id: integer, name: string, email:string, subscribed: boolean)

# Migration to add unsubscribe_token and token_expires_at to Users
class AddUnsubscribeTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :unsubscribe_token, :string
    add_column :users, :token_expires_at, :datetime
  end
end

# User model
class User < ApplicationRecord
  has_secure_token :unsubscribe_token

  # Generate a new unsubscribe token with an expiration
  def generate_unsubscribe_token
    regenerate_unsubscribe_token
    update!(token_expires_at: 3.days.from_now)
  end

  # Validate the unsubscribe token
  def valid_unsubscribe_token?(token)
    unsubscribe_token == token && token_expires_at && token_expires_at.future?
  end
end

# Service to handle email notifications
class NotificationService
  def self.send_new_post_notification(post)
    User.where(subscribed: true).find_each do |user|
      user.generate_unsubscribe_token
      NotificationMailer.new_post_email(user.email, user.unsubscribe_token, post).deliver_now
    end
  end
end

# SubscriptionsController
class SubscriptionsController < ApplicationController
  def unsubscribe
    user = User.find_by(unsubscribe_token: params[:token])

    if user&.valid_unsubscribe_token?(params[:token])
      user.update!(subscribed: false, unsubscribe_token: nil, token_expires_at: nil)
      render json: { message: "You have successfully unsubscribed." }, status: :ok
    else
      render json: { error: "The unsubscribe link is invalid or has expired." }, status: :unprocessable_entity
    end
  end
end
