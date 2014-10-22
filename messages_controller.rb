class MessagesController < ApplicationController
  load_and_authorize_resource
  before_filter :notification_list
  before_filter :auth_user!
  
  def index
		if params[:sel_elem]
			@sel_msg_id = params[:sel_elem]
		end
		@inbox_messages = Message.where(:current_receiver => current_user.id,:receiver_deleted=> false).desc(:created_at)
		if !@inbox_messages.blank?
			@unique_messages_by_sender = @inbox_messages.uniq{|mes| mes.current_sender }
			@unread_messages = @inbox_messages.where(:status => false)
			if !@unique_messages_by_sender.blank?
				@last_sender = @unique_messages_by_sender.first.current_sender
			end
		end
  end
  def show_message_list
  	@last_sender = params[:user_id]
  end
	def create
		if !params[:message][:body].blank?
			user = User.find(params[:message][:current_receiver])
			@user = current_user
			@user1 = user
			@message = Message.create!(params[:message])
			@sender = "/messages/private/#{current_user.id}/#{user.id}"
			@receiver = "/messages/private/#{user.id}/#{current_user.id}"
			@sender_id = "#{current_user.id}-#{user.id}"
			@receiver_id = "#{user.id}-#{current_user.id}"
			@unread_messages = Message.any_of({:current_sender=> current_user.id},{:current_receiver => current_user.id}).where(:status => false)
		else
			render :nothing => true
		end
	end
	def get_messages_count
		@unread_messages = Message.where(:status => false,:current_receiver => current_user.id).to_a
		@count = @unread_messages.size
		return @count
		#render :nothing => true
	end
	def status_update
		@message = Message.find(params[:id])
		@message.update_attributes(:status => true)
		render :nothing => true
	end
	def my_status_update
		@messages = Message.where(:current_receiver => params[:user_id], :current_sender => params[:lister_id])
		puts @messages.count
		@messages.each do |m|
			m.update_attributes(:status => true)
		end
		render :nothing => true
	end
	def unread_messages 
		@messages = Message.where(:current_receiver => current_user.id)
		@unread_messages = Message.where(:status => false,:current_receiver => current_user.id)
		@online_users = User.where(:last_request_at.gte => 5.seconds.ago, :id.ne =>current_user.id)
	end
	
	def openchat
		@messages = Message.all
		@sender = User.find(params[:sender_id])
	end
	def delete_this_conversation
		@other_user = params[:user_id]
		@messages = Message.any_of({:current_sender => current_user.id,:current_receiver => @other_user,:sender_deleted=>false},{:current_sender => @other_user,:current_receiver =>current_user.id,:receiver_deleted=>false}).asc(:created_at)
	end
	def update_multiple
		params[:messages].each do |msg_id|
			mes = Message.find(msg_id) 
			if mes.current_sender.to_s == current_user.id.to_s
				mes.update_attributes(:sender_deleted => true)
			else
				mes.update_attributes(:receiver_deleted=> true)
			end
		end
		redirect_to messages_path #, notice: 'Contact was successfully updated.'
	end
end
