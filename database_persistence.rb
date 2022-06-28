require "pg"
class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "blogs")
    end
    @logger = logger
  end

  def query(sql, *params)
    @logger.info "#{sql} : #{params}"
    @db.exec_params(sql, params)
  end

  def find_user(id)
    sql = "SELECT * FROM users WHERE id = $1"
    result = query(sql, id)
    tup = result.first
    {id: tup["id"], user_name: tup["user_name"], blog_name: tup["blog_name"]}
  end

  def find_posts_by_user(id)
    sql = "SELECT * FROM blog_posts WHERE blogger_id = $1"
    result = query(sql, id)
    result.map do |todo_tuple|
      ({id: todo_tuple["id"].to_i,
        date: todo_tuple["post_date"],
        title: todo_tuple["post_title"],
        text: todo_tuple["blog_body"],
        img: todo_tuple["image_src"],
      })
    end
  end

  def change_photo(filename, post_id)
    sql = "UPDATE blog_posts SET image_src = $1 WHERE id = $2"
    result = query(sql, filename, post_id)
  end

  def add_user_blog(user_name, password, blog_name)
    sql = "INSERT INTO users (user_name, blog_name, password) VALUES ($1, $2, $3);"
    result = query(sql, user_name, blog_name, password)
  end

  def add_post(title, date, text, blogger_id)
    default_photo = 'Default.jpg'
    sql = "INSERT INTO blog_posts (blogger_id, post_date, post_title, blog_body, image_src) VALUES ($1, $2, $3, $4, $5)"
    query(sql, blogger_id, date, title, text, default_photo)
  end

  def get_last_post_id(user_id)
    sql = "SELECT id FROM blog_posts WHERE blogger_id = $1"
    result = query(sql, user_id)

    ids = result.map do |todo_tuple|
      ({id: todo_tuple["id"],
      })
    end
    ids.last[:id]
  end

  def delete_account(id)
    sql1 = "DELETE FROM blog_posts WHERE blogger_id = $1"
    result1 = query(sql1, id)
    sql2 = "DELETE FROM users WHERE id = $1"
    result2 = query(sql2, id)
  end

  def retrieve_password_for_user(user_name)
    sql = "SELECT id, password FROM users WHERE user_name = $1"
    result = query(sql, user_name)
    tup = result.first
    if tup === nil
      { no_user: true }
    else
      { password: tup["password"], id: tup["id"] }
    end
  end

  def get_list_of_users_and_blogs
    sql = "SELECT * FROM users"
    result = query(sql)
    result.map do |todo_tuple|
      ({id: todo_tuple["id"].to_i,
        user_name: todo_tuple["user_name"],
        blog_name: todo_tuple["blog_name"],
      })
    end
  end

  def update_post(title, date, text, post_id)
    sql = "UPDATE blog_posts SET post_title = $1, post_date = $2, blog_body = $3 WHERE id = $4"
    result = query(sql, title, date, text, post_id)
  end

  def delete_post(post_id)
    sql = "DELETE FROM blog_posts WHERE id = $1"
    result = query(sql, post_id)
  end

  def find_post_by_id(post_id)
    sql = "SELECT * FROM blog_posts WHERE id = $1"
    result = query(sql, post_id)
    todo_tuple = result.first
    {
      id: todo_tuple["id"].to_i,
      date: todo_tuple["post_date"],
      title: todo_tuple["post_title"],
      text: todo_tuple["blog_body"],
      img: todo_tuple["image_src"],
      blogger_id: todo_tuple["blogger_id"],
    }
  end
end
