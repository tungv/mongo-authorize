config = require 'config'

mongoose = require 'mongoose'
try
  mongoose.connection.close()
  mongoose.connect config.mongo.connection
catch ex
  console.error ex


mongoose.models = {}

itemSchema = mongoose.Schema {
  age: Number,
  eyeColor: String,
  name: String,
  gender: String,
  email: String,
  phone: String
}

mongoose.model 'item', itemSchema

ItemModel = mongoose.model 'item', itemSchema

items = [
  {
    "age": 21,
    "eyeColor": "green",
    "name": "Antonia Sutton",
    "gender": "female",
    "email": "antoniasutton@digifad.com",
    "phone": "+1 (904) 529-3234"
  },
  {
    "age": 29,
    "eyeColor": "brown",
    "name": "Mays Pate",
    "gender": "male",
    "email": "mayspate@digifad.com",
    "phone": "+1 (916) 485-2063"
  },
  {
    "age": 32,
    "eyeColor": "blue",
    "name": "Ruthie Dean",
    "gender": "female",
    "email": "ruthiedean@digifad.com",
    "phone": "+1 (986) 584-3180"
  },
  {
    "age": 39,
    "eyeColor": "green",
    "name": "Julia Douglas",
    "gender": "female",
    "email": "juliadouglas@digifad.com",
    "phone": "+1 (883) 417-3313"
  },
  {
    "age": 28,
    "eyeColor": "blue",
    "name": "Theresa Stein",
    "gender": "female",
    "email": "theresastein@digifad.com",
    "phone": "+1 (832) 589-2369"
  },
  {
    "age": 36,
    "eyeColor": "blue",
    "name": "Rosanne Poole",
    "gender": "female",
    "email": "rosannepoole@digifad.com",
    "phone": "+1 (864) 579-2495"
  },
  {
    "age": 30,
    "eyeColor": "blue",
    "name": "Hope Velez",
    "gender": "female",
    "email": "hopevelez@digifad.com",
    "phone": "+1 (866) 416-2480"
  },
  {
    "age": 32,
    "eyeColor": "brown",
    "name": "Daniels Brady",
    "gender": "male",
    "email": "danielsbrady@digifad.com",
    "phone": "+1 (938) 574-2423"
  },
  {
    "age": 30,
    "eyeColor": "brown",
    "name": "Carey Hughes",
    "gender": "female",
    "email": "careyhughes@digifad.com",
    "phone": "+1 (810) 504-3850"
  },
  {
    "age": 32,
    "eyeColor": "green",
    "name": "Camacho Carter",
    "gender": "male",
    "email": "camachocarter@digifad.com",
    "phone": "+1 (988) 450-2162"
  },
  {
    "age": 28,
    "eyeColor": "brown",
    "name": "Margery Rowland",
    "gender": "female",
    "email": "margeryrowland@digifad.com",
    "phone": "+1 (970) 480-2628"
  },
  {
    "age": 33,
    "eyeColor": "green",
    "name": "Rosa Holcomb",
    "gender": "female",
    "email": "rosaholcomb@digifad.com",
    "phone": "+1 (897) 561-2638"
  },
  {
    "age": 21,
    "eyeColor": "brown",
    "name": "Hawkins Leonard",
    "gender": "male",
    "email": "hawkinsleonard@digifad.com",
    "phone": "+1 (960) 585-3899"
  },
  {
    "age": 25,
    "eyeColor": "blue",
    "name": "Robert Whitney",
    "gender": "female",
    "email": "robertwhitney@digifad.com",
    "phone": "+1 (920) 483-2584"
  },
  {
    "age": 32,
    "eyeColor": "blue",
    "name": "Conner Cantrell",
    "gender": "male",
    "email": "connercantrell@digifad.com",
    "phone": "+1 (803) 431-2452"
  },
  {
    "age": 32,
    "eyeColor": "green",
    "name": "Gretchen Graves",
    "gender": "female",
    "email": "gretchengraves@digifad.com",
    "phone": "+1 (886) 577-3465"
  },
  {
    "age": 25,
    "eyeColor": "brown",
    "name": "Blankenship Shepherd",
    "gender": "male",
    "email": "blankenshipshepherd@digifad.com",
    "phone": "+1 (845) 402-3387"
  },
  {
    "age": 36,
    "eyeColor": "blue",
    "name": "Lowery Rodriguez",
    "gender": "male",
    "email": "loweryrodriguez@digifad.com",
    "phone": "+1 (966) 547-3710"
  },
  {
    "age": 26,
    "eyeColor": "brown",
    "name": "Goff Goodman",
    "gender": "male",
    "email": "goffgoodman@digifad.com",
    "phone": "+1 (997) 549-2049"
  },
  {
    "age": 21,
    "eyeColor": "brown",
    "name": "Simon Giles",
    "gender": "male",
    "email": "simongiles@digifad.com",
    "phone": "+1 (847) 533-2955"
  }
]

ItemModel.remove ()->
  for item in items
    doc = new ItemModel item
    doc.save()