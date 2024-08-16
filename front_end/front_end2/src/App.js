import { Routes, Route,BrowserRouter} from 'react-router-dom';
import './App.css';
import Login from './Components/Login'
import Signup from './Components/Signup'
import Profile from './Components/Profile'


function App() {
  return (
    <BrowserRouter>
      <Routes>
          <Route path="/" element={<Login />} />
          <Route path="/signups" element={<Signup />} />
          <Route path="/profile" element={<Profile />} />

      </Routes>
    </BrowserRouter>
  );
}

export default App;