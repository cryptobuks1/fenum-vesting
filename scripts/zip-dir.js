const process = require('process');
const zipdir = require('zip-dir');



const time = new Date();
const timeStamp = (time.getTime()/1000).toFixed(0);
const timeDate = time.toISOString();
const timeString = `${timeStamp}-${timeDate}`;

const zippedPath = process.argv[2] || '.';
const prefix = process.argv[3] ? `${process.argv[3]}-` : '';
const saveTopath = `./archive-${prefix}${timeString}.zip`;

const options = {
  saveTo: saveTopath,
  filter: (path, stat) => {
    let includeFile = true;
    if (/\.git/.test(path)) includeFile = false;
    if (/\.zip$/.test(path)) includeFile = false;
    if (/node_modules/.test(path)) includeFile = false;
    return includeFile;
  },
  each: (path) => console.log(path, 'added!'),
};

zipdir(zippedPath, options, function (err, buffer) {
  console.log('Done!');
});
