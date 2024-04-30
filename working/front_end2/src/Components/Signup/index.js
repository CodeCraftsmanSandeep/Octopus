import './index.css'
import {Component} from 'react'
import {Link} from 'react-router-dom'

class Signup extends Component {
     render() {
          return (
            <div className="signup-container">
                <form className="signup-form">
                <h2>Sign Up</h2>

                <div className="form-group">
                    <label htmlFor="Username"> Username </label>
                    <input type="text" id="Username" name="Username" placeholder="Enter unique username" size="40" required/>
                </div>

                <div className="form-group">
                    <label htmlFor="email">Email</label>
                    <input type="email" id="email" name="email" placeholder="Enter unique email-id" size="40" required/>
                </div>
                
                <div className="form-group">
                    <label htmlFor="name">Name</label>
                    <input type="text" id="name" name="name" placeholder="Enter your name" size="40" required/>
                </div>

                <div className="form-group">
                    <label htmlFor="password">Password</label>
                    <input type="password" id="password" name="password" placeholder="Enter password" size="40" required/>
                </div>
                <button type="submit" id = "submit" >Sign Up</button>

                <p>Have an account? <Link to="/"> Login </Link></p>

                </form>
            </div>
               )
        }
}

export default Signup