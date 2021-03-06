app=$1
input=$2
output='./applications/'
pre_pro='./preprocess_views'
controller='./controller_model_analysis'
call=$input/'calls.txt'
schema=$input/db/'schema.rb'
mkdir $output/$app
echo "move app dir to applications "
cp -r $input/app/* $output/$app/
cp $call $output/$app
cp $schema $output/$app
echo "finished moving"

echo "preprocessing"
echo $app
cd $pre_pro; pwd; ruby main.rb -a $app; cd ../
echo "finish preprocessing"

echo "jruby get dataflow"
cd $output; pwd; python generate_dataflow_log.py $app; cd ../
echo "FINISH dataflow"

echo "run analysis"
cd $controller; pwd; ruby main.rb -a -d ../$output/$app/
echo "FINISH analysis"

