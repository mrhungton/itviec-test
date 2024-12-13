User.joins(:posts)
  .select("users.*, COUNT(posts.id) AS post_count")
  .group("users.id")
  .order("post_count DESC")
