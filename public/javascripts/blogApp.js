class BlogApp {
  constructor() {
    this.bindEvents()
  }

  bindEvents() {
    document.querySelector('#delete').addEventListener('click', this.confirmDelete);
  }

  confirmDelete = (event) => {
    if (window.confirm("Are you sure you want to delete this post?")) {
      
    }else {
      event.preventDefault();
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const blog = new BlogApp();
});
