import {Component} from 'react'
import {Link,useNavigate  } from 'react-router-dom'
import Cookies from 'js-cookie'
import './index.css'

class MyComponent extends Component {
  state = {username: '', password: '',loginstatus:false, showSubmitError: false}

  onChangeUsername = event => {
    this.setState({username: event.target.value})
    // const userDetails = {username:"sai", password:"paswo"}
    // Cookies.set('jwt_token', userDetails, {expires: 30})
    // this.setState({loginstatus: true})
    }
  onChangePassword = event => {
    this.setState({password: event.target.value})
  }
  SubmitForm = async event => {
    event.preventDefault()
    const {username, password} = this.state
    const userDetails = {username, password}
    // const apiUrl = 'https://login'
    
    const apiUrl = `http://localhost:2000/login?username=${username}&password=${password}`
    
    // const options = {
    //   method: 'POST',
    //   body: JSON.stringify(userDetails),
    // }
    const options = {
      method: 'GET',
      // body: JSON.stringify(userDetails),
    }
    
    const response = await fetch(apiUrl, options)
    //const data = await response.json()
    console.log(response)
    // if(repsone == -1){

    // }else{

    // }

    // if (response.ok === true) {
    //   Cookies.set('jwt_token', userDetails, {expires: 30})
    //   this.setState({loginstatus: true})
    // }
  }
  handleRedirect = () => {
    this.props.navigate('/profile');
  };
    render() {
      const {username, password, showSubmitError, errorMsg,loginstatus} = this.state
        console.log("sai")
        if(loginstatus) {
          this.handleRedirect()
        }
        return (
          <div className="login-container">
            <form className="login-form">
              <h2>Login</h2>
        
              <div className="form-group">
                <label htmlFor="Username" >Username</label>
                <input type="text" id="Username" 
                  onChange={this.onChangeUsername}
                  value={username}name="Username" 
                  placeholder="Enter your username" size="40" required/>
              </div>
              
              <div className="form-group">
                <label htmlFor="password">Password</label>
                <input type="password" value={password}
                  onChange={this.onChangePassword} id="password" name="password" placeholder="Enter your password" size="40" required/>
              </div>
              <button type="submit" id = "submit" onClick={this.SubmitForm}>Login</button>
              <p>Don't have an account? <Link to="/signups">Sign up</Link></p>
            </form>
            
          </div>
        )
    }
  }
  
  function Login(props) {
    const navigate = useNavigate();
  
    return <MyComponent {...props} navigate={navigate} />;
  }

  export default Login
