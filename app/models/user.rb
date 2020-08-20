class User < ActiveRecord::Base
    has_many :categories
    has_many :gifs, through: :categories
    @@current_user = false

    has_secure_password

    def self.current_user
        @@current_user
    end

    def self.current_user=(user)
        @@current_user = user
    end

    def self.login
        system('clear')

        username = TTY::Prompt.new.ask("Please enter your username:")
        password = TTY::Prompt.new.mask("Please enter your password:")

        if !self.find_by(username: username).try(:authenticate, password)
            print TTY::Box.error("Incorrect username or password!")
            sleep(2.0)
            self.login
        else
            self.current_user = self.find_by(username: username)
            print TTY::Box.success("Success! Signing you in..")
            sleep(2.0)
            self.current_user.task_selection_screen
        end
        
    end

    def self.username_taken?(username)
        self.find_by(username: username)
    end

    def self.sign_up
        system('clear')

        username = TTY::Prompt.new.ask("Please enter your username:")
        if username_taken?(username)
            TTY::Prompt.new.keypress("That username is taken. Push Enter to try again.", keys: [:return])
            self.sign_up
        else
            password = TTY::Prompt.new.mask("Please enter your password:")
        
            new_user = self.create(username: username, password: password)
            print TTY::Box.success("Welcome back #{username}!")
            sleep(2.0)
            new_user.task_selection_screen
        end
    end

    def sign_out
        self.class.current_user = false
        print TTY::Box.success("Successfully signed out!")
        sleep(2.0)
        system 'clear'
        welcome_screen
    end

    def task_selection_screen
        system('clear')

        task = TTY::Prompt.new.select("What would you like to do?", %w(
            Create\ a\ category
            View\ existing\ categories
            Search\ for\ a\ gif
            View\ the\ top\ trending\ gifs
            Sign\ out
        ))

        case task
        when "Create a category"
            self.create_category
        when "View existing categories"
            self.view_categories
        when "Search for a gif"
            Gif.search_giphy
        when "View the top trending gifs"
            Gif.view_top_trending
        when "Sign out"
            self.sign_out
        end
    end

    def create_category
        system('clear')

        new_category_name = TTY::Prompt.new.ask("What is the name of the new category?\n")

        self.categories.find_or_create_by(name: new_category_name, user_id: self.id)

        print TTY::Box.success("#{new_category_name} has been successfully created!")
        sleep(2.0)
        self.task_selection_screen
    end

    # User class (instance method)
    def view_categories
        system('clear')

        if self.categories.length == 0
            input = TTY::Prompt.new.select("You have not created any categories yet. What would you like to do?", %w(Create\ a\ category Return\ to\ menu))

            if input == "Create a category"
                self.create_category
            elsif input == "Return to menu"
                self.task_selection_screen
            end

        else
            category_names = self.categories.all.map { |category| category.name } << "Return to menu"

            category_choice = TTY::Prompt.new.enum_select("Select a category to view its gifs, or return to menu.", category_names)

            if self.categories.find_by(name: category_choice)
                self.view_gifs(category_choice)
            elsif category_choice == "Return to menu"
                self.task_selection_screen
            end
        end
    end

    def view_gifs(category_name)
        system('clear')

        chosen_category = self.categories.find_by(name: category_name)
        
        gif_names = chosen_category.gifs.all.map { |gif| gif.nickname } << "Return to menu"

        gif_choice = TTY::Prompt.new.enum_select("Select a gif, or return to menu.", gif_names)

        gif_ins = chosen_category.gifs.find_by(nickname: gif_choice)
        if chosen_category.gifs.find_by(nickname: gif_choice)
            # display, then delete/share/move
            self.delete_share_move(gif_ins)
        elsif gif_choice == "Return to menu"
            self.task_selection_screen
        end
    end

    def delete_share_move(gif_ins)
        Gif.display_gif(gif_ins.link)
        options = %w(Delete Move\ categories Share Return\ to\ menu)
        answer = TTY::Prompt.new.select("What would you like to do with this gif?", options)
        case answer
        when "Delete"
            gif_ins.delete
            system 'clear'
            print TTY::Box.warn("Gif successfully deleted.")
            sleep(2.0)
            self.task_selection_screen
        when "Move categories"
            
        when "Share"
            gif_ins.share_gif
        when "Return to menu"
            self.task_selection_screen
        end
    end

end