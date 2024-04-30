import './index.css'
import {Component} from 'react'
import Cookies from 'js-cookie'

class Profile extends Component {
     render() {
        const token = Cookies.get('jwt_token')
        console.log(token)
          return (
            <div>
                <header>
                    <h1>User Profile</h1>
                    <nav>
                    <ul>
                        <li><a href="#">Username</a></li>
                        <li><a href="#">Email</a></li>
                        <li><a href="#">Repositories</a></li>
                        <li><a href="#">Storage Used</a></li>
                        <li><a href="#">Last Visit</a></li>
                        <li><a href="#">Sign Out</a></li>
                    </ul>
                    </nav>
                </header>

                <div class="container">
                    <h2>Welcome, Username!</h2>
                    <div class="profile-info">
                    <p><strong>Username:</strong> JohnDoe</p>
                    <p><strong>Email:</strong> johndoe@example.com</p>
                    <p><strong>Number of Repositories:</strong> 10</p>
                    <p><strong>Storage Used:</strong> 50 MB</p>
                    <p><strong>Last Visit:</strong> April 20, 2024</p>
                    </div>
                    <button class="view-repositories">View All Repositories</button>
                </div>

                <footer>
                    <p>&copy; 2024 @octopus All rights reserved.</p>
                </footer>

                <div class="repository-container">
                    
                </div>

                <script src="script.js"></script>
            </div>
               )
        }
}

export default Profile