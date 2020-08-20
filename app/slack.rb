module Slack
@@access_token = ENV['SLACK_ACCESS_TOKEN']
@@gif_link

    def self.access_token
        @@access_token
    end

    def self.access_token=(token)
        @@access_token = token
    end

    def self.gif_link
        @@gif_link
    end

    def self.gif_link=(link)
        @@gif_link = link
    end

    def self.slack_gif(gif_link)
        self.gif_link = gif_link

        if !self.access_token
            self.sign_in
        end

        prompt = TTY::Prompt.new
        answer = prompt.select("Would you like to share this with a channel or send a direct message?", %w(share\ with\ a\ channel send\ a\ direct\ message never\ mind,\ return\ to\ menu))
        
        case answer
        when "share with a channel"
            self.select_group_channel
        when "send a direct message"
            self.select_dm_convo
        when "never mind, return to menu"
            User.current_user.task_selection_screen
        end
    end

    def self.sign_in
        puts "Please authorize this app. When your browser window opens, click \"Allow\"."
        puts "When your browser tries to redirect you, copy the portion of the url between \"code=\" and \"&state\" and paste it here."
        puts "Push Enter to continue."
        gets.chomp
        self.launch_url_for_code
        code = gets.chomp

        self.convert_code_to_access_token(code)
    end

    def self.launch_url_for_code
        Launchy.open("https://slack.com/oauth/v2/authorize?client_id=#{ENV['SLACK_CLIENT_ID']}&user_scope=chat%3Awrite")
    end
    
    # access token for testing purposes xoxp-1309750153941-1304391363350-1311279061490-5336b92ed4a34d1952d32fff54294069
    def self.convert_code_to_access_token(code)
        url = "https://slack.com/api/oauth.v2.access?code=#{code}&client_id=#{ENV['SLACK_CLIENT_ID']}&client_secret=#{ENV['SLACK_CLIENT_SECRET']}"
        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)
        token = JSON.parse(response.body)
        self.access_token = token["authed_user"]["access_token"]
    end
    

    def self.select_group_channel
        prompt = TTY::Prompt.new
        url = "https://slack.com/api/conversations.list?token=#{self.access_token}&types=public_channel%2Cprivate_channel&pretty=1"
        uri = URI.parse(url)
        response = Net::HTTP::get_response(uri)
        all_info = JSON.parse(response.body)
        
        names = all_info["channels"].map do |channel|
            channel["name"]
        end

        answer = prompt.enum_select("Which channel would you like to post to?", names)

        selected_channel = all_info["channels"].find do |channel|
            channel["name"] == answer
        end

        channel_id = selected_channel["id"]
        self.post_something_as_user(channel_id)
    end

    def self.select_dm_convo
        prompt = TTY::Prompt.new
        url = "https://slack.com/api/conversations.list?token=#{self.access_token}&types=im&pretty=1"
        uri = URI.parse(url)
        response = Net::HTTP::get_response(uri)
        all_info = JSON.parse(response.body)

        

        users = all_info["channels"].map do |channel|
            channel["user"]
        end

        names = users.map do |user|
            get_users_name(user)
        end

        answer = prompt.enum_select("Who would you like to send this to?", names)

        # get user id by name
        selected_user = users.find do |user|
            self.get_users_name(user) == answer
        end

        # have user, now go back to channels and find matching id
        selected_channel = all_info["channels"].find do |channel|
            channel["user"] == selected_user
        end

        channel_id = selected_channel["id"]
        self.post_something_as_user(channel_id)
    end
    
    def self.get_users_name(user)
        url = "https://slack.com/api/users.info?token=#{self.access_token}&user=#{user}&pretty=1"
        uri = URI.parse(url)
        response = Net::HTTP::get_response(uri)
        all_info = JSON.parse(response.body)
        all_info["user"]["name"]
    end

    def self.message_text
        puts "What would you like to say along with the link?"
        gets.chomp
    end

    def self.post_something_as_user(channel_id)
        #sends to selected channel (note this does not select the channel for you or enter the text)
        text = self.message_text
        link = self.gif_link
        combined_message = text + link

        url = "https://slack.com/api/chat.postMessage?token=#{self.access_token}&channel=#{channel_id}&text=#{combined_message}&as_user=true&pretty=1"
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/json"
        req_options = {
        use_ssl: uri.scheme == "https",
        }
    
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
        end

        puts "Your message has been sent!"
    end
end