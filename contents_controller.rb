class HomeController < ApplicationController
  
	before_filter :authenticate_user! ,:except => [:subscription_page]
  
	def index
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		@contents = Content.joins("left join hives h on contents.hive_id = h.id and contents.content_url is null").where("h.is_private = false or h is null and contents.content_url is null").to_a
		ContentInterestHive.all.each do |ci|
			@contents << ci.content unless ci.content_id.nil?
		end
		@contents = @contents.uniq.sort_by{|x| x[:created_at]}.reverse.paginate(:per_page => 8, :page => params[:page])
		@views = Visit.group(:content_id).count 
		if params[:user_id]
			@user = User.find(params[:user_id])
		else
			@user = current_user
		end	
		@outside_contents = @contents.select { |el| el.content_url != nil}
		@original_contents = @contents.select { |el| el.content_url == nil}
		@hives = current_user.hives
		if request.xhr?
			sleep(2) # make request a little bit slower to see loader :-)
			render :partial =>  @contents
		end
	end
  
	def subscription_page
		@subscribe_user = SubscribeUser.new
		render :layout => false
	end


			#Getting all contents for archive section basing on subhives aswell owner
	def show_contents
		@id = params[:id].to_i;
		@user =  User.find(params[:user_id])
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		if @id == 0
			@original_contents = @user.contents.where( :hive_id => 0 ,:content_url => nil,:is_publication_content =>  false).to_a
			@interests = Interest.find(:all, :conditions => ["hive_id = ? AND user_id = ? AND content_id is ? ", '0', @user.id, nil])
			@views = Visit.group(:content_id).count
			@curators = @user.all_following(:conditions => {:hive_id => 0})
			@hived_user_contents = [];
			@user.content_interest_hives.each do |c| 
				if !c.content_id.nil? && c.hive_id == 0
					if Content.find(c.content_id).content_url.nil?
						@original_contents.push(Content.find(c.content_id))
					else
						@hived_user_contents.push(Content.find(c.content_id))
					end
				end 
			end
			@all_contents = @hived_user_contents + @original_contents
			@all_contents = @all_contents.sort_by{|x| x[:created_at]}.reverse
			@hivenger_original_interests = []
			@all_contents.each do |c|
				@hivenger_original_interests << c.hivenger_original_interests.where(:allow_interest => true)
			end
			@hivenger_original_interests.flatten.uniq.each do |ho|
				@interests << Interest.find(ho.interest_id)
			end

			@interests = @interests.flatten.uniq
			@original_contents = @original_contents.uniq.sort_by{|x| x[:created_at]}.reverse
			@hived_user_contents = @hived_user_contents.uniq.sort_by{|x| x[:created_at]}.reverse
			@hived_count = @all_contents.size + @interests.size + @curators.size
		else
			@shn.where(:hive_id => @id).update_all( status: true )
			@hive = Hive.find(@id.to_i)
			@original_contents = @hive.contents.where(:content_url => nil,:is_publication_content =>  false).to_a
			@interests = Interest.find(:all, :conditions => ["hive_id = ? AND user_id = ? AND content_id is ? ", @id, @user.id, nil])
			@views = Visit.group(:content_id).count
			@curators = @hive.user.all_following(:conditions => {:hive_id => @id})
			@hived_user_contents = [];
			ContentInterestHive.find(:all, conditions:["hive_id =?", @id.to_i]).each do |c| 
				if Content.find(c.content_id).content_url.nil?
					@original_contents.push(Content.find(c.content_id))
				else
					@hived_user_contents.push(Content.find(c.content_id))
				end
			end
			@all_contents = @hived_user_contents + @original_contents
			@all_contents = @all_contents.sort_by{|x| x[:created_at]}.reverse
			@hivenger_original_interests = []
			@all_contents.each do |c|
				@hivenger_original_interests << c.hivenger_original_interests.where(:allow_interest => true)
			end
			@hivenger_original_interests.flatten.uniq.each do |ho|
				@interests << Interest.find(ho.interest_id)
			end
			@original_contents = @original_contents.uniq.sort_by{|x| x[:created_at]}.reverse
			@hived_user_contents = @hived_user_contents.uniq.sort_by{|x| x[:created_at]}.reverse
			@hived_count = @all_contents.size + @interests.size + @curators.size
		end
	end

	#Following all are degree formation actions like, Onedegree, twodegree and three degree
	def show_degree_formation
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		@one_deg = ContentInspire.find(params[:id].to_i)
		render :partial => "show_degree_formation"
	end

	def show_content_two_degree_formation
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		@ins = ContentInspire.find(params[:id].to_i)
		@one_deg = Content.find(params[:one_deg].to_i)
		render :partial => "show_content_two_degree_formation"
	end

	def show_content_two_degree_inner
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		@ins = ContentInspire.find(params[:id].to_i)
		@one_deg = Content.find(params[:one_deg].to_i)
		render :partial => "show_content_two_degree_inner"
	end	

	def show_content_three_degree_formation
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		@c = Content.find(params[:id].to_i)
		@one_deg = Content.find(params[:one_deg].to_i)
		@two_deg = Content.find(params[:two_deg].to_i)
		@index = params[:index].to_i
		render :partial => "show_content_three_degree_formation"
	end

	def show_content_three_degree_inner
		@api = Embedly::API.new(:key => '1c2d469ead564363b4b20ebe8efe91bc')
		@c = Content.find(params[:id].to_i)
		@one_deg = Content.find(params[:one_deg].to_i)
		@two_deg = Content.find(params[:two_deg].to_i)
		@index = params[:index].to_i
		render :partial => "show_content_three_degree_inner"
	end
end
