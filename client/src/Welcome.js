import React from 'react';
import { Link } from 'react-router-dom';

const Welcome = () => {
  const username = localStorage.getItem('username');

  const handleLogout = () => {
    localStorage.removeItem('username');
    console.log('DB_SERVER:', process.env.DB_SERVER);
    window.location.href = '/'; // Redirect to home
  };

  return (
    <div>
      {username ? (
        <>
          <h1>Welcome back, {username}!</h1>
          <button onClick={handleLogout}>Logout</button>
        </>
      ) : (
        <>
          <h1>Welcome to Our Application!</h1>
          <p>If you don't have an account, you can <Link to="/signup">sign up here</Link>.</p>
        </>
      )}
    </div>
  );
};

export default Welcome;