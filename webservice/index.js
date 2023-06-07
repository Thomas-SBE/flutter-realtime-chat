const express = require("express");
const { Server } = require("socket.io");
const http = require("http");
const jwt = require("jsonwebtoken");
const { Client } = require("pg");
const { randomInt, createHash } = require("crypto");
const { Configuration, OpenAIApi } = require("openai");
const cors = require('cors');
const multer = require('multer');
const SharpMulter = require("sharp-multer");
const fs = require('fs');
const path = require('path');
const { channel } = require("diagnostics_channel");

require("dotenv").config();
const configuration = new Configuration({
    apiKey: process.env.OPENAI_API_KEY,
});

const openai = new OpenAIApi(configuration);
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*"
    }
});
const db = new Client();
const storage = SharpMulter ({
    destination:(req, file, callback) =>callback(null, "uploads"),
    imageOptions:{
     fileFormat: "jpg",
     quality: 80,
     resize: { width: 512, height: 512 },
       }
 });
const uploader = multer({ storage });

const usernamePrefixes = ["Funny", "Sad", "Happy", "Crazy", "Sneaky", "Cool"];
const usernameKeywords = ["Panda", "Banana", "Lizard", "Snake", "Person"];


const HttpCodes = {
    OK: 200,
    UNAUTHORIZED: 401,
    BAD_REQUEST: 400,
    NOT_FOUND: 404,
    CONFLICT: 409,
    INTERNAL_ERROR: 500
};

app.use(express.json());
app.use(cors({origin: '*', allowedHeaders: ['Content-Type', 'Authorization'], exposedHeaders: ['Content-Type', 'Authorization']}));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')))

function authGuard(req, res, next) {
    try {
        var token = req.headers.authorization.split(' ')[1];
        var decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        var userId = decodedToken.userId;
        req.auth = {
            'userId': userId
        };
        next();
    }catch(e){
        res.status(HttpCodes.UNAUTHORIZED).json({ e });
    }
}

// INIT
const init = async () => {
    await db.connect();
    await db.query("create table if not exists user_credentials (user_id serial primary key, email varchar(255) unique, password varchar(256));");
    await db.query("create table if not exists user_details (user_id serial primary key, username varchar(255), image_url text, region_code varchar(8), constraint fk_credentials foreign key(user_id) references user_credentials(user_id));");
    await db.query("create table if not exists channels (channel_id serial primary key, name varchar(255), image_url text, admin serial, constraint fk_channel_admin foreign key(admin) references user_details(user_id));");
    await db.query("create table if not exists channel_connections (channel_id serial, user_id serial, constraint fk_channel_channel foreign key(channel_id) references channels(channel_id) on delete cascade, constraint fk_channel_user foreign key(user_id) references user_details(user_id) on delete cascade);");
    await db.query("create table if not exists messages (message_id serial primary key, channel_id serial, sent_by serial, content text, sent timestamp with time zone default CURRENT_TIMESTAMP, constraint fk_message_channel foreign key(channel_id) references channels(channel_id) on delete cascade, constraint fk_message_user foreign key(sent_by) references user_details(user_id));");

    // ADDING AI ACCOUNT 
    let aid = await db.query("insert into user_credentials values ($1,$2,$3) on conflict do nothing returning user_id;", [0,"ce580752336eef3a3b3995cebf0055555c9fac80f6509e04788bea67", "f67bf7033995298dfc0faefe31516656330c58132"]);
    if(aid.rowCount > 0)
        await db.query("insert into user_details(user_id,username,region_code) values ($1,$2,$3) on conflict do nothing;", [0,"AI", "OPENIA"]);

    // DEBUG
    let uid = await db.query("insert into user_credentials(email,password) values ($1,$2) on conflict do nothing returning user_id;", ["debug", "0b8e9e995d8d77f1e4770f0f79665aee6f3f70247b3735422daba73df4c3096f"]);
    if(uid.rowCount > 0)
        await db.query("insert into user_details(user_id,username,region_code) values ($1,$2,$3) on conflict do nothing;", [uid.rows[0].user_id,"Debugger", "DBG"]);
    
    
        console.log("Database initialization has finished !");
};
init();

app.get("/ping", (req, res) => res.status(HttpCodes.OK).send());
app.post("/auth/login", async (req, res) => {
    if(typeof req.body.email === 'undefined' || typeof req.body.password === 'undefined') return res.status(HttpCodes.BAD_REQUEST).send();
    if(!(typeof req.body.email == "string") || !(typeof req.body.password == "string")) return res.status(HttpCodes.BAD_REQUEST).send();

    const result = await db.query('SELECT user_id FROM user_credentials WHERE email=$1 AND password=$2;', [req.body.email, req.body.password]);
    if(result.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({'e': "INVALID_CREDENTIALS"});
    if(result.rowCount > 1) return res.status(HttpCodes.INTERNAL_ERROR).send({'e': "DUPLICATE_USERS"});

    const credentials = result.rows[0];
    var token = jwt.sign({'userId': credentials.user_id}, process.env.JWT_SECRET, {expiresIn: '48h'});
    res.status(HttpCodes.OK).header("Authorization", `Bearer ${token}`).send();
});
app.post("/auth/register", async (req, res) => {
    if(typeof req.body.email === 'undefined' || typeof req.body.password === 'undefined') return res.status(HttpCodes.BAD_REQUEST).send();
    if(!(typeof req.body.email == "string") || !(typeof req.body.password == "string")) return res.status(HttpCodes.BAD_REQUEST).send();

    let username = usernamePrefixes[randomInt(usernamePrefixes.length)] + usernameKeywords[randomInt(usernameKeywords.length)];

    try{
        const result = await db.query('insert into user_credentials(email,password) values ($1,$2) returning user_id;', [req.body.email, req.body.password]);
        const details = await db.query('insert into user_details(user_id,username,region_code) values($1,$2,$3) returning username, user_id;', [result.rows[0].user_id, username, "DEF"]);
        if(details.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({'e': "UNKNOWN"});
        const credentials = details.rows[0];
        var token = jwt.sign({'userId': credentials.user_id}, process.env.JWT_SECRET, {expiresIn: '48h'});
        return res.status(HttpCodes.OK).header("Authorization", `Bearer ${token}`).send(Object.assign({}, result.rows[0], details.rows[0]))       
    }catch(e){
        return res.status(HttpCodes.CONFLICT).send({ e });
    }    
});

app.get("/me", authGuard, async (req, res) => {
    var uid = req.auth.userId;
    // SELF INFORMATIONS
    const self = await db.query('SELECT username, region_code, user_id, image_url FROM user_details WHERE user_id=$1;', [uid]);
    if(self.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({'e': "COULD_NOT_FIND_DETAILS"});
    // CHANNELS INFORMATIONS
    const channels = await db.query('SELECT channel_id, name, image_url FROM channels NATURAL JOIN channel_connections WHERE user_id=$1;', [uid]);
    res.status(HttpCodes.OK).send({
        'self': self.rows[0],
        'channels': channels.rows
    });
});

app.patch("/me", authGuard, async (req, res) => {
    var uid = req.auth.userId;
    const authorizedChanges = ["image_url", "username"];
    let changes = Object.entries(req.body).map(([key, value]) => {
        console.log(key, value);
        if(authorizedChanges.includes(key)) return `${key}='${value.replace("'", "`")}'`;
        else return null;
    });
    changes = changes.filter((v) => v != null);
    console.log(changes);
    const mods = await db.query(`UPDATE user_details SET ${changes.join(", ")} WHERE user_id=$1 RETURNING *;`, [uid]);
    if(mods.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': "USER_NOT_UPDATED" });
    
    let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${uid}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
    io.sockets.in(userHash).emit("user_update", mods.rows[0]);
    
    return res.status(HttpCodes.OK).send(mods.rows[0]);
});

app.get("/invite/userlist/:chan", authGuard, async (req, res) => {
    let chan_id = req.params.chan;
    let user_id = req.auth.userId;

    const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1;", [chan_id]);
    let rule = members.rows.map((val) => `user_id != ${val["user_id"]}`);
    rule.push("user_id != 0");
    const users = await db.query(`SELECT username, region_code, user_id, image_url FROM user_details WHERE ${rule.join(" AND ")};`);

    return res.status(HttpCodes.OK).send(users.rows);
});

app.get("/user/:id", authGuard, async (req, res) => {
    var uid = req.params.id;
    const self = await db.query('SELECT username, region_code, user_id FROM user_details WHERE user_id=$1;', [uid]);
    if(self.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({'e': "COULD_NOT_FIND_DETAILS"});
    res.status(HttpCodes.OK).send({
        'info': self.rows[0],
    });
});

app.post("/channel/new", authGuard, async (req, res) => {
    if(!Array.isArray(req.body.members)) return res.status(HttpCodes.BAD_REQUEST).send();
    if(!(typeof req.body.name === "string")) return res.status(HttpCodes.BAD_REQUEST).send();
    if(!req.body.name.replace(/\s/g, '').length) return res.status(HttpCodes.BAD_REQUEST).send({ 'e': "NAME_NULL_OR_EMPTY" });

    req.body.members.push(req.auth.userId);
    req.body.members = req.body.members.filter((e,p) => { return req.body.members.indexOf(e) == p });

    try{
        const channel = await db.query("insert into channels(name, admin) values ($1,$2) returning channel_id, name;", [req.body.name, req.auth.userId]);
        let to_insert = [];
        req.body.members.forEach(e => {
            to_insert.push(`(${channel.rows[0].channel_id},${e})`);
        });
        const members = await db.query(`insert into channel_connections(channel_id,user_id) values ${ to_insert.join(',') } returning user_id;`);

        for(let i = 0; i < members.rowCount; i++){
            let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
            io.sockets.in(userHash).emit("channel_update", channel.rows[0]);
        }

        return res.status(HttpCodes.OK).send(channel.rows[0]);
    }catch(e){
        console.log(e);
        return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': e });
    }
});

app.get("/channel/info/:id", authGuard, async (req, res) => {
    let chan_id = req.params.id;
    let user_id = req.auth.userId;
    // CHECK IF IS IN CHANNEL
    const check = await db.query("SELECT channel_id FROM channel_connections WHERE user_id=$1;", [user_id]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });
    const channel = await db.query("SELECT * FROM channels WHERE channel_id=$1;", [chan_id]);
    if(channel.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({e: "CHANNEL_ID_NOT_FOUND"});
    const members = await db.query("SELECT username, user_id, image_url FROM channel_connections NATURAL JOIN user_details WHERE channel_id=$1;", [chan_id]);
    channel.rows[0]["members"] = members.rows;
    return res.status(HttpCodes.OK).send(channel.rows[0]);
});

app.patch("/channel/info/:id", authGuard, async (req,res) => {
    let chan_id = req.params.id;
    let user_id = req.auth.userId;

    if(!req.body) return res.status(HttpCodes.BAD_REQUEST).send({"e": "MISSING_BODY"});
    if(Object.keys(req.body).length <= 0) return res.status(HttpCodes.OK).send({});

    // CHECK IF IS IN CHANNEL
    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [user_id, chan_id]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });
    if(check.rows[0].admin != user_id) return res.status(HttpCodes.UNAUTHORIZED).send({'e': "NOT_ADMIN"});

    const authorizedChanges = ["image_url", "name"];
    let changes = Object.entries(req.body).map(([key, value]) => {
        console.log(key, value);
        if(authorizedChanges.includes(key)) return `${key}='${value.replace("'", "`")}'`;
        else return null;
    });
    changes = changes.filter((v) => v != null);
    console.log(changes);
    const mods = await db.query(`UPDATE channels SET ${changes.join(", ")} WHERE channel_id=$1 RETURNING *;`, [chan_id]);
    if(mods.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': "CHANNEL_NOT_UPDATED" });

    const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1", [chan_id]);
    for(let i = 0; i < members.rowCount; i++){
        let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
        io.sockets.in(userHash).emit("channel_update", mods.rows[0]);
    }

    return res.status(HttpCodes.OK).send(mods.rows[0]);
});

app.post("/channel/invite/:channel/:user", authGuard, async (req, res) => {
    let chan = req.params.channel;
    let uid = req.params.user;

    const checkUserExists = await db.query("SELECT user_id FROM user_details WHERE user_id=$1;", [uid]);
    if(checkUserExists.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "USER_NOT_FOUND" })
    const checkChannelExists = await db.query("SELECT channel_id FROM channels WHERE channel_id=$1;", [chan]);
    if(checkChannelExists.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "CHANNEL_NOT_FOUND" })

    const checkIfSelfIn = await db.query("SELECT channel_id FROM channel_connections WHERE user_id=$1 AND channel_id=$2;", [req.auth.userId, chan]);
    if(checkIfSelfIn.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });
    const checkIfOtherIn = await db.query("SELECT channel_id FROM channel_connections WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(checkIfOtherIn.rowCount > 0) return res.status(HttpCodes.CONFLICT).send({ 'e': "ALREADY_MEMBER_OF_CHANNEL" });

    const invite = await db.query("INSERT INTO channel_connections(channel_id,user_id) VALUES ($1,$2) RETURNING user_id;", [chan, uid]);
    if(invite.rowCount <= 0){
        return res.status(HttpCodes.INTERNAL_ERROR).send();
    }

    const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1", [chan]);
    for(let i = 0; i < members.rowCount; i++){
        let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
        io.sockets.in(userHash).emit("channel_update", invite.rows[0]);
    }

    return res.status(HttpCodes.OK).send();
});

app.post("/channel/kick/:channel/:user", authGuard, async (req, res) => {
    let chan = req.params.channel;
    let uid = req.params.user;

    if(uid == req.auth.userId) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "CANNOT_KICK_YOURSELF", 'msg': "Bien tenté mais j'y ai déja pensé..." });

    const checkChannelExists = await db.query("SELECT channel_id,admin FROM channels WHERE channel_id=$1;", [chan]);
    if(checkChannelExists.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "CHANNEL_NOT_FOUND" })

    if(req.auth.userId != checkChannelExists.rows[0].admin) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "ADMIN_REQUIRED" });

    const checkUserExists = await db.query("SELECT user_id FROM user_details WHERE user_id=$1;", [uid]);
    if(checkUserExists.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "USER_NOT_FOUND" })
    const checkIfOtherIn = await db.query("SELECT channel_id FROM channel_connections WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(checkIfOtherIn.rowCount <= 0) return res.status(HttpCodes.CONFLICT).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });

    const kick = await db.query("DELETE FROM channel_connections WHERE channel_id=$1 AND user_id=$2 RETURNING user_id;", [chan, uid]);
    if(kick.rowCount <= 0){
        return res.status(HttpCodes.INTERNAL_ERROR).send();
    }

    let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${kick.rows[0].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
    io.sockets.in(userHash).emit("channel_update", kick.rows[0]);

    const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1", [chan]);
    for(let i = 0; i < members.rowCount; i++){
        userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
        io.sockets.in(userHash).emit("channel_update", kick.rows[0]);
    }

    return res.status(HttpCodes.OK).send();
});

app.post("/channel/leave/:id", authGuard, async (req, res) => {
    let chan_id = req.params.id;
    let user_id = req.auth.userId;
    // CHECK IF IS IN CHANNEL
    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [user_id, chan_id]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });
    if(check.rows[0].admin == user_id){
        const removeEveryone = await db.query("DELETE FROM channels WHERE channel_id=$1 AND admin=$2 RETURNING channel_id;", [chan_id, user_id]);
        if(removeEveryone.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "CHANNEL_NOT_FOUND" });
        return res.status(HttpCodes.OK).send({ 'msg': "DELETED_CHANNEL" });
    }else{
        const removeSelf = await db.query("DELETE FROM channel_connections WHERE channel_id=$1 AND user_id=$2 RETURNING channel_id;", [chan_id, user_id]);
        if(removeSelf.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "CHANNEL_NOT_FOUND" });
        return res.status(HttpCodes.OK).send({ 'msg': "LEFT_CHANNEL" });
    }
});

app.post("/channel/send/:id", authGuard, async (req, res) => {
    let uid = req.auth.userId;
    let chan = req.params.id;

    if(typeof req.body.content === 'undefined') return res.status(HttpCodes.BAD_REQUEST).send();
    if(!(typeof req.body.content == "string")) return res.status(HttpCodes.BAD_REQUEST).send();
    let content = req.body.content;

    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });

    const insertion = await db.query("INSERT INTO messages(channel_id,sent_by,content) VALUES ($1, $2, $3) RETURNING message_id, content, channel_id, sent_by, sent;", [chan, uid, content]);
    if(insertion.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': "UNABLE_TO_SEND" });

    const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1", [chan]);
    for(let i = 0; i < members.rowCount; i++){
        let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
        io.sockets.in(userHash).emit("message_update", insertion.rows[0]);
    }

    return res.status(HttpCodes.OK).send(insertion.rows[0]);
});

app.get("/channel/messages/:id", authGuard, async (req, res) => {
    let uid = req.auth.userId;
    let chan = req.params.id;

    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });

    const messages = await db.query("SELECT r.message_id,r.sent_by,r.sent,r.content FROM (SELECT * FROM messages AS m WHERE m.channel_id=$1) AS r ORDER BY r.sent DESC;", [chan]);

    return res.status(HttpCodes.OK).send(messages.rows.reverse());
})

app.delete("/channel/messages/:chan/:message_id", authGuard, async (req, res) => {
    let uid = req.auth.userId;
    let chan = req.params.chan;
    let mess_id = req.params.message_id;

    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });

    const mess_del = await db.query("DELETE FROM messages WHERE channel_id=$1 AND message_id=$2 AND sent_by=$3 RETURNING message_id;", [chan, mess_id, uid]);
    if(mess_del.rowCount <= 0) return res.status(HttpCodes.NOT_FOUND).send({ 'e': "MESSAGE_NOT_FOUND" });

    const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1", [chan]);
        for(let i = 0; i < members.rowCount; i++){
            let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
            io.sockets.in(userHash).emit("message_deletion", mess_del.rows[0]);
    }

    return res.status(HttpCodes.OK).send(mess_del.rows[0]);
});

var gpt_queue = [];

app.post("/channel/messages/:chan/gpt", authGuard, async (req, res) => {
    let chan = req.params.chan;
    let uid = req.auth.userId;

    if(gpt_queue.includes(chan)){
        while(gpt_queue.includes(chan)){
            await new Promise((res) => setTimeout(res, 1000));
        }
        return res.status(200).send({});
    }

    gpt_queue.push(chan);

    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });
    const messages = await db.query("SELECT r.message_id,r.sent_by,r.sent,r.content FROM (SELECT * FROM messages AS m WHERE m.channel_id=$1 AND m.sent_by!=0) AS r ORDER BY r.sent DESC LIMIT 1;", [chan]);

    const mapped = messages.rows.map((v) => {return {"role": v.content.startsWith('∞') ? "assistant" : "user", "content": v.content}});
    if(mapped.length <= 0){
        return res.status(204).send({e: "NO_MESSAGE_TO_CONTEXT"});
    }

    try{
        const response = await openai.createChatCompletion({
            model: "gpt-3.5-turbo",
            messages: mapped,
            max_tokens: 2048,
        });
        const insertion = await db.query("INSERT INTO messages(channel_id,sent_by,content) VALUES ($1, $2, $3) RETURNING message_id, content, channel_id, sent_by, sent;", [chan, 0, `∞${response.data.choices[0].message.content}`]);
        if(insertion.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': "UNABLE_TO_SEND" });
        
        const members = await db.query("SELECT user_id FROM channel_connections WHERE channel_id=$1", [chan]);
        for(let i = 0; i < members.rowCount; i++){
            let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${members.rows[i].user_id}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
            io.sockets.in(userHash).emit("message_update", insertion.rows[0]);
        }
        
        gpt_queue = gpt_queue.filter((v) => v != chan);

        return res.status(HttpCodes.OK).send(insertion.rows[0]);
    }catch(e){
        gpt_queue = gpt_queue.filter(v => v != chan);
        return res.status(500).send({'e': e});
    }
    

    
});

app.post("/upload_image/user", authGuard, uploader.single("file"), async (req, res) => {
    let uid = req.auth.userId;

    if(req.file.size > 5242880) return res.status(HttpCodes.CONFLICT).send({'e': "FILE_TOO_BIG"});

    let fileuid = createHash('sha256').update(`PROFILE_PICTURE_${uid}`).digest("hex");

    if(fs.existsSync(`./uploads/${fileuid}`)) fs.unlinkSync(`./uploads/${fileuid}`);
    fs.rename(`./uploads/${req.file.filename}`, `./uploads/${fileuid}`, (err) => { if(err) console.log(err); });

    const mods = await db.query(`UPDATE user_details SET image_url='/uploads/${fileuid}' WHERE user_id=$1 RETURNING *;`, [uid]);
    if(mods.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': "CHANNEL_NOT_UPDATED" });

    let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${uid}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
    io.sockets.in(userHash).emit("user_update", mods.rows[0]);

    return res.status(HttpCodes.OK).send();
});

app.post("/upload_image/channel/:channel", authGuard, uploader.single("file"), async (req, res) => {
    let uid = req.auth.userId;
    let chan = req.params.channel;

    if(req.file.size > 5242880) return res.status(HttpCodes.CONFLICT).send({'e': "FILE_TOO_BIG"});

    let fileuid = createHash('sha256').update(`CHANNEL_PICTURE_${uid}`).digest("hex");

    const check = await db.query("SELECT channel_id, admin FROM channel_connections NATURAL JOIN channels WHERE user_id=$1 AND channel_id=$2;", [uid, chan]);
    if(check.rowCount <= 0) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_MEMBER_OF_CHANNEL" });
    if(check.rows[0].admin != uid) return res.status(HttpCodes.UNAUTHORIZED).send({ 'e': "NOT_ADMIN" });

    if(fs.existsSync(`./uploads/${fileuid}`)) fs.unlinkSync(`./uploads/${fileuid}`);
    fs.rename(`./uploads/${req.file.filename}`, `./uploads/${fileuid}`, (err) => { if(err) console.log(err); });

    const mods = await db.query(`UPDATE channels SET image_url='/uploads/${fileuid}' WHERE channel_id=$1 RETURNING *;`, [chan]);
    if(mods.rowCount <= 0) return res.status(HttpCodes.INTERNAL_ERROR).send({ 'e': "CHANNEL_NOT_UPDATED" });

    let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${uid}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
    io.sockets.in(userHash).emit("channel_update", mods.rows[0]);

    return res.status(HttpCodes.OK).send();
});

// SOCKET IO CONNECTION MANAGEMENT
io.use((socket, next) => {
    if(socket.handshake.query && socket.handshake.query.token){
        jwt.verify(socket.handshake.query.token, process.env.JWT_SECRET, (err, decoded) => {
            if(err){
                return next(new Error("JWT_AUTH_ERR"));
            }
            socket.decoded = decoded;
            next();
        })
    }else{
        return next(new Error("JWT_AUTH_MISSING"));
    }
})
.on('connection', socket => {
    let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${socket.decoded.userId}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
    socket.join(userHash);
    console.log(`User #${socket.decoded.userId} Connected to Socket: Private channel [${userHash}].`);

    socket.on('disconnect', () => {
        let userHash = createHash('sha256').update(`${process.env.JWT_SECRET}+${socket.decoded.userId}+${process.env.SOCKET_UID_GENERATOR_PASSPHRASE}`).digest('hex');
        socket.leave(userHash);
        console.log(`User #${socket.decoded.userId} Disconnected from Socket: Private channel [${userHash}].`);
    })
})



server.listen(process.env.SERVER_PORT, '0.0.0.0', () => {
    console.log(`Server is online and listening on port ${process.env.SERVER_PORT}`);
})
