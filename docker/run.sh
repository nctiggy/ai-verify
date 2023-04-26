# Setup MongoDB
mongod > /dev/null &
sleep 5  #This is to allow mongod to startup properly

# Run Setup
./init_setup.sh
rm -rf /app/init_setup.sh

# Setup Redis Server
service redis-server start

# Run AI Testkit API
cd /app/ai-verify-api/
mkdir output
node app.mjs &

# Run AI Testkit Toolbox
cd /app/ai-verify-toolbox/
python3 toolbox.py &

# Run AI Testkit UI
cd /app/ai-verify-ui/
ng serve --disable-host-check --host 0.0.0.0
