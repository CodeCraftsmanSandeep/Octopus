
////////////////////////////Step 1 Rendering your html page////////////////////////////////////////////
const express=require('express');
const cors = require('cors');
const app=express();
const port= 2000;

const bodyParser=require('body-parser'); 

app.use(express.static(__dirname));

app.get("/", (req, res) => {
    res.sendFile(__dirname + "/signup.html");
});

app.use(cors({
    origin: 'http://localhost:3001'
  }));
  

app.use(bodyParser.urlencoded({extended: false}))
// app.get('c',function(req,res){
//     console.log("Data Saved");
// })

////////////////////////////Step 2 Connection with Postgres////////////////////////////////////////////

const {Pool,Client}= require('pg');

// const connectionString='postgressql://username:password@localhost:5432/databasename'
const connectionString='postgressql://postgres:60686068@localhost:5432/octopus'


const client= new Client({
    connectionString:connectionString
})


////////////////////////////Step 3  Inserting the values////////////////////////////////////////////

client.connect()

app.post("/",(req,res)=>{
    const { Username,email,name,password}=req.body
    client.query(' SELECT create_user($1, $2, $3, $4) AS create_user_result; ', [Username, name,email, password], (err,queryRes)=> {
        console.log(err,queryRes);
        // console.log(res.command);    
        //alert("Data Saved");
        const createUserResult = queryRes.rows[0].create_user_result;
        console.log('Result of create_user:', createUserResult);
        if(createUserResult == false){
            /* problem in sign up */
            res.sendFile(__dirname + "/error_page.html");
        }else{
            /* go to login */
            res.sendFile(__dirname + "/login.html");
        }
    })
})

app.post("/login",(req,res)=>{
    console.log("dasdfdfv");
    const { username, password}=req;

    client.query(' SELECT * FROM developer where developer.user_name = $1;  ', [username, password], (err,queryRes)=> {
        
        console.log(err,queryRes);

        const loginUserResult = queryRes.rows[0].login_user_result;
        console.log('Result of loginUserResult:', loginUserResult);
        res.send(loginUserResult);
    })
})
// client.end(); // need to see!!

app.listen(port, () => {
    console.log(`Example app listening on port ${port}!`)
});