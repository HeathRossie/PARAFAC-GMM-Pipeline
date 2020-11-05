# PARAFAC-GMM-Pipeline
A pipeline for unsupervised characterization of time-series data

Automatic clustering of behaviors is increasingly important analytic pipeline.
This repo shows a demonstration of combiation of parallel factor analysis + Gaussian mixture model.

The classification of trials may be useful to answer several research questions. For example,
- what kind of behavioral patterns occured
- or emerged across experimental sessions
- how certain epxerimental manupulation affects behavioral patterns
- neural corraltes of specific behavioural patterns


A common analytic pipeline in computational ethology classfies the moment-to-memoment behavioral states by clustering frame-by-frame features.
The current method utilizes a bit different strategy; it characterizes whole trials sequences, which can be multiple time-series as a behaviral patterns.


# (0) Data 
Imagine you got multiple time-series data like these
![image](https://user-images.githubusercontent.com/17682330/98270383-1c44fe00-1f8f-11eb-8858-d1966ab47b35.png)

These are hypothetical data of several trials. Red and blue lines are supposed as features obtained in an experiment.
For example, these may be x and y positional data from tracking, distance metrics, orientations, or movement velocity.

# (1) Dimensionality reducntion
The  pipeline demostrated in this repo project time-series features in a trial into one location of abstract features space, using parallel factor analysis.

![image](https://user-images.githubusercontent.com/17682330/98271300-17cd1500-1f90-11eb-9799-6b7fcffd285f.png)

Colours represent the true classes generated in a demo-data.

# (2) Clustering Behavioral patterns
Obviously, true classes are unknown in a real reserach. Thus, we need to estimate the classes by clustering method.
Here, using Gaussian Mixture model, the classes are automatically detected.

![image](https://user-images.githubusercontent.com/17682330/98271834-a80b5a00-1f90-11eb-9edf-1fdb89319a88.png)


The number of patterns can be inferred by BIC. But note that BIC tend to be unnecessarily increase as a function of the number of the patterns in GMM.
It may be recommendable to use a threshold as a cut-off point.

![image](https://user-images.githubusercontent.com/17682330/98273252-56fc6580-1f92-11eb-9d12-171875236547.png)



# (3) Visualization of each behaviral pattern

Finally, it would be informative to visualize each behavioural sequences.

Because this demonstration is not from real data, trajectories are not interpretable.
However, you would get good inspection from visualization of your own real dataset.

![image](https://user-images.githubusercontent.com/17682330/98273002-0dac1600-1f92-11eb-899f-d5f7e2b119ff.png)


