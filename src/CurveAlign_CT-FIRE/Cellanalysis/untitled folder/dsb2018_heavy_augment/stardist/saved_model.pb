Х
о
:
Add
x"T
y"T
z"T"
Ttype:
2	
x
Assign
ref"T

value"T

output_ref"T"	
Ttype"
validate_shapebool("
use_lockingbool(
~
BiasAdd

value"T	
bias"T
output"T" 
Ttype:
2	"-
data_formatstringNHWC:
NHWCNCHW
h
ConcatV2
values"T*N
axis"Tidx
output"T"
Nint(0"	
Ttype"
Tidxtype0:
2	
8
Const
output"dtype"
valuetensor"
dtypetype
ь
Conv2D

input"T
filter"T
output"T"
Ttype:
2"
strides	list(int)"
use_cudnn_on_gpubool(""
paddingstring:
SAMEVALID"-
data_formatstringNHWC:
NHWCNCHW" 
	dilations	list(int)


Conv2DBackpropInput
input_sizes
filter"T
out_backprop"T
output"T"
Ttype:
2"
strides	list(int)"
use_cudnn_on_gpubool(""
paddingstring:
SAMEVALID"-
data_formatstringNHWC:
NHWCNCHW" 
	dilations	list(int)

.
Identity

input"T
output"T"	
Ttype
N
IsVariableInitialized
ref"dtype
is_initialized
"
dtypetype
д
MaxPool

input"T
output"T"
Ttype0:
2	"
ksize	list(int)(0"
strides	list(int)(0""
paddingstring:
SAMEVALID":
data_formatstringNHWC:
NHWCNCHWNCHW_VECT_C
e
MergeV2Checkpoints
checkpoint_prefixes
destination_prefix"
delete_old_dirsbool(
=
Mul
x"T
y"T
z"T"
Ttype:
2	

NoOp
M
Pack
values"T*N
output"T"
Nint(0"	
Ttype"
axisint 
C
Placeholder
output"dtype"
dtypetype"
shapeshape:
~
RandomUniform

shape"T
output"dtype"
seedint "
seed2int "
dtypetype:
2"
Ttype:
2	
E
Relu
features"T
activations"T"
Ttype:
2	
x
ResizeNearestNeighbor
images"T
size
resized_images"T"
Ttype:
2		"
align_cornersbool( 
o
	RestoreV2

prefix
tensor_names
shape_and_slices
tensors2dtypes"
dtypes
list(type)(0
l
SaveV2

prefix
tensor_names
shape_and_slices
tensors2dtypes"
dtypes
list(type)(0
P
Shape

input"T
output"out_type"	
Ttype"
out_typetype0:
2	
H
ShardedFilename
basename	
shard

num_shards
filename
0
Sigmoid
x"T
y"T"
Ttype:

2
і
StridedSlice

input"T
begin"Index
end"Index
strides"Index
output"T"	
Ttype"
Indextype:
2	"

begin_maskint "
end_maskint "
ellipsis_maskint "
new_axis_maskint "
shrink_axis_maskint 
N

StringJoin
inputs*N

output"
Nint(0"
	separatorstring 
:
Sub
x"T
y"T
z"T"
Ttype:
2	
s

VariableV2
ref"dtype"
shapeshape"
dtypetype"
	containerstring "
shared_namestring "serve*1.12.02v1.12.0-rc2-3-ga6d8ffae09еш

inputPlaceholder*
dtype0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ*6
shape-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ
 
	dist_maskPlaceholder*
dtype0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ*6
shape-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ
v
conv2d_1/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"             
`
conv2d_1/random_uniform/minConst*
dtype0*
_output_shapes
: *
valueB
 *О
`
conv2d_1/random_uniform/maxConst*
valueB
 *>*
dtype0*
_output_shapes
: 
Б
%conv2d_1/random_uniform/RandomUniformRandomUniformconv2d_1/random_uniform/shape*
seedБџх)*
T0*
dtype0*&
_output_shapes
: *
seed2ќўP
}
conv2d_1/random_uniform/subSubconv2d_1/random_uniform/maxconv2d_1/random_uniform/min*
_output_shapes
: *
T0

conv2d_1/random_uniform/mulMul%conv2d_1/random_uniform/RandomUniformconv2d_1/random_uniform/sub*
T0*&
_output_shapes
: 

conv2d_1/random_uniformAddconv2d_1/random_uniform/mulconv2d_1/random_uniform/min*
T0*&
_output_shapes
: 

conv2d_1/kernel
VariableV2*
dtype0*&
_output_shapes
: *
	container *
shape: *
shared_name 
Ш
conv2d_1/kernel/AssignAssignconv2d_1/kernelconv2d_1/random_uniform*
use_locking(*
T0*"
_class
loc:@conv2d_1/kernel*
validate_shape(*&
_output_shapes
: 

conv2d_1/kernel/readIdentityconv2d_1/kernel*&
_output_shapes
: *
T0*"
_class
loc:@conv2d_1/kernel
[
conv2d_1/ConstConst*
valueB *    *
dtype0*
_output_shapes
: 
y
conv2d_1/bias
VariableV2*
shared_name *
dtype0*
_output_shapes
: *
	container *
shape: 
­
conv2d_1/bias/AssignAssignconv2d_1/biasconv2d_1/Const*
T0* 
_class
loc:@conv2d_1/bias*
validate_shape(*
_output_shapes
: *
use_locking(
t
conv2d_1/bias/readIdentityconv2d_1/bias*
T0* 
_class
loc:@conv2d_1/bias*
_output_shapes
: 
s
"conv2d_1/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      
ѕ
conv2d_1/convolutionConv2Dinputconv2d_1/kernel/read*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations

Ј
conv2d_1/BiasAddBiasAddconv2d_1/convolutionconv2d_1/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
s
conv2d_1/ReluReluconv2d_1/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
v
conv2d_2/random_uniform/shapeConst*%
valueB"              *
dtype0*
_output_shapes
:
`
conv2d_2/random_uniform/minConst*
valueB
 *ьбН*
dtype0*
_output_shapes
: 
`
conv2d_2/random_uniform/maxConst*
valueB
 *ьб=*
dtype0*
_output_shapes
: 
В
%conv2d_2/random_uniform/RandomUniformRandomUniformconv2d_2/random_uniform/shape*
T0*
dtype0*&
_output_shapes
:  *
seed2ф*
seedБџх)
}
conv2d_2/random_uniform/subSubconv2d_2/random_uniform/maxconv2d_2/random_uniform/min*
T0*
_output_shapes
: 

conv2d_2/random_uniform/mulMul%conv2d_2/random_uniform/RandomUniformconv2d_2/random_uniform/sub*&
_output_shapes
:  *
T0

conv2d_2/random_uniformAddconv2d_2/random_uniform/mulconv2d_2/random_uniform/min*
T0*&
_output_shapes
:  

conv2d_2/kernel
VariableV2*
dtype0*&
_output_shapes
:  *
	container *
shape:  *
shared_name 
Ш
conv2d_2/kernel/AssignAssignconv2d_2/kernelconv2d_2/random_uniform*
T0*"
_class
loc:@conv2d_2/kernel*
validate_shape(*&
_output_shapes
:  *
use_locking(

conv2d_2/kernel/readIdentityconv2d_2/kernel*
T0*"
_class
loc:@conv2d_2/kernel*&
_output_shapes
:  
[
conv2d_2/ConstConst*
dtype0*
_output_shapes
: *
valueB *    
y
conv2d_2/bias
VariableV2*
shared_name *
dtype0*
_output_shapes
: *
	container *
shape: 
­
conv2d_2/bias/AssignAssignconv2d_2/biasconv2d_2/Const*
validate_shape(*
_output_shapes
: *
use_locking(*
T0* 
_class
loc:@conv2d_2/bias
t
conv2d_2/bias/readIdentityconv2d_2/bias*
T0* 
_class
loc:@conv2d_2/bias*
_output_shapes
: 
s
"conv2d_2/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:
§
conv2d_2/convolutionConv2Dconv2d_1/Reluconv2d_2/kernel/read*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(*
paddingSAME
Ј
conv2d_2/BiasAddBiasAddconv2d_2/convolutionconv2d_2/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
s
conv2d_2/ReluReluconv2d_2/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
а
max_pooling2d_1/MaxPoolMaxPoolconv2d_2/Relu*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
T0*
data_formatNHWC*
strides
*
ksize
*
paddingVALID

&down_level_0_no_0/random_uniform/shapeConst*%
valueB"              *
dtype0*
_output_shapes
:
i
$down_level_0_no_0/random_uniform/minConst*
dtype0*
_output_shapes
: *
valueB
 *ьбН
i
$down_level_0_no_0/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *ьб=
Ф
.down_level_0_no_0/random_uniform/RandomUniformRandomUniform&down_level_0_no_0/random_uniform/shape*
T0*
dtype0*&
_output_shapes
:  *
seed2­у*
seedБџх)

$down_level_0_no_0/random_uniform/subSub$down_level_0_no_0/random_uniform/max$down_level_0_no_0/random_uniform/min*
T0*
_output_shapes
: 
В
$down_level_0_no_0/random_uniform/mulMul.down_level_0_no_0/random_uniform/RandomUniform$down_level_0_no_0/random_uniform/sub*
T0*&
_output_shapes
:  
Є
 down_level_0_no_0/random_uniformAdd$down_level_0_no_0/random_uniform/mul$down_level_0_no_0/random_uniform/min*&
_output_shapes
:  *
T0

down_level_0_no_0/kernel
VariableV2*
shared_name *
dtype0*&
_output_shapes
:  *
	container *
shape:  
ь
down_level_0_no_0/kernel/AssignAssigndown_level_0_no_0/kernel down_level_0_no_0/random_uniform*
use_locking(*
T0*+
_class!
loc:@down_level_0_no_0/kernel*
validate_shape(*&
_output_shapes
:  
Ё
down_level_0_no_0/kernel/readIdentitydown_level_0_no_0/kernel*
T0*+
_class!
loc:@down_level_0_no_0/kernel*&
_output_shapes
:  
d
down_level_0_no_0/ConstConst*
valueB *    *
dtype0*
_output_shapes
: 

down_level_0_no_0/bias
VariableV2*
shape: *
shared_name *
dtype0*
_output_shapes
: *
	container 
б
down_level_0_no_0/bias/AssignAssigndown_level_0_no_0/biasdown_level_0_no_0/Const*
validate_shape(*
_output_shapes
: *
use_locking(*
T0*)
_class
loc:@down_level_0_no_0/bias

down_level_0_no_0/bias/readIdentitydown_level_0_no_0/bias*
_output_shapes
: *
T0*)
_class
loc:@down_level_0_no_0/bias
|
+down_level_0_no_0/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      

down_level_0_no_0/convolutionConv2Dmax_pooling2d_1/MaxPooldown_level_0_no_0/kernel/read*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations

У
down_level_0_no_0/BiasAddBiasAdddown_level_0_no_0/convolutiondown_level_0_no_0/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 

down_level_0_no_0/ReluReludown_level_0_no_0/BiasAdd*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
T0

&down_level_0_no_1/random_uniform/shapeConst*%
valueB"              *
dtype0*
_output_shapes
:
i
$down_level_0_no_1/random_uniform/minConst*
valueB
 *ьбН*
dtype0*
_output_shapes
: 
i
$down_level_0_no_1/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *ьб=
Ф
.down_level_0_no_1/random_uniform/RandomUniformRandomUniform&down_level_0_no_1/random_uniform/shape*
seedБџх)*
T0*
dtype0*&
_output_shapes
:  *
seed2ЬВ

$down_level_0_no_1/random_uniform/subSub$down_level_0_no_1/random_uniform/max$down_level_0_no_1/random_uniform/min*
T0*
_output_shapes
: 
В
$down_level_0_no_1/random_uniform/mulMul.down_level_0_no_1/random_uniform/RandomUniform$down_level_0_no_1/random_uniform/sub*&
_output_shapes
:  *
T0
Є
 down_level_0_no_1/random_uniformAdd$down_level_0_no_1/random_uniform/mul$down_level_0_no_1/random_uniform/min*&
_output_shapes
:  *
T0

down_level_0_no_1/kernel
VariableV2*
dtype0*&
_output_shapes
:  *
	container *
shape:  *
shared_name 
ь
down_level_0_no_1/kernel/AssignAssigndown_level_0_no_1/kernel down_level_0_no_1/random_uniform*
T0*+
_class!
loc:@down_level_0_no_1/kernel*
validate_shape(*&
_output_shapes
:  *
use_locking(
Ё
down_level_0_no_1/kernel/readIdentitydown_level_0_no_1/kernel*
T0*+
_class!
loc:@down_level_0_no_1/kernel*&
_output_shapes
:  
d
down_level_0_no_1/ConstConst*
valueB *    *
dtype0*
_output_shapes
: 

down_level_0_no_1/bias
VariableV2*
shape: *
shared_name *
dtype0*
_output_shapes
: *
	container 
б
down_level_0_no_1/bias/AssignAssigndown_level_0_no_1/biasdown_level_0_no_1/Const*
T0*)
_class
loc:@down_level_0_no_1/bias*
validate_shape(*
_output_shapes
: *
use_locking(

down_level_0_no_1/bias/readIdentitydown_level_0_no_1/bias*
T0*)
_class
loc:@down_level_0_no_1/bias*
_output_shapes
: 
|
+down_level_0_no_1/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

down_level_0_no_1/convolutionConv2Ddown_level_0_no_0/Reludown_level_0_no_1/kernel/read*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(*
paddingSAME
У
down_level_0_no_1/BiasAddBiasAdddown_level_0_no_1/convolutiondown_level_0_no_1/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 

down_level_0_no_1/ReluReludown_level_0_no_1/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
Я
max_0/MaxPoolMaxPooldown_level_0_no_1/Relu*
T0*
strides
*
data_formatNHWC*
ksize
*
paddingVALID*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 

&down_level_1_no_0/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"          @   
i
$down_level_1_no_0/random_uniform/minConst*
valueB
 *ЋЊЊН*
dtype0*
_output_shapes
: 
i
$down_level_1_no_0/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *ЋЊЊ=
Ф
.down_level_1_no_0/random_uniform/RandomUniformRandomUniform&down_level_1_no_0/random_uniform/shape*
T0*
dtype0*&
_output_shapes
: @*
seed2к*
seedБџх)

$down_level_1_no_0/random_uniform/subSub$down_level_1_no_0/random_uniform/max$down_level_1_no_0/random_uniform/min*
T0*
_output_shapes
: 
В
$down_level_1_no_0/random_uniform/mulMul.down_level_1_no_0/random_uniform/RandomUniform$down_level_1_no_0/random_uniform/sub*
T0*&
_output_shapes
: @
Є
 down_level_1_no_0/random_uniformAdd$down_level_1_no_0/random_uniform/mul$down_level_1_no_0/random_uniform/min*
T0*&
_output_shapes
: @

down_level_1_no_0/kernel
VariableV2*
dtype0*&
_output_shapes
: @*
	container *
shape: @*
shared_name 
ь
down_level_1_no_0/kernel/AssignAssigndown_level_1_no_0/kernel down_level_1_no_0/random_uniform*
T0*+
_class!
loc:@down_level_1_no_0/kernel*
validate_shape(*&
_output_shapes
: @*
use_locking(
Ё
down_level_1_no_0/kernel/readIdentitydown_level_1_no_0/kernel*&
_output_shapes
: @*
T0*+
_class!
loc:@down_level_1_no_0/kernel
d
down_level_1_no_0/ConstConst*
dtype0*
_output_shapes
:@*
valueB@*    

down_level_1_no_0/bias
VariableV2*
shape:@*
shared_name *
dtype0*
_output_shapes
:@*
	container 
б
down_level_1_no_0/bias/AssignAssigndown_level_1_no_0/biasdown_level_1_no_0/Const*
use_locking(*
T0*)
_class
loc:@down_level_1_no_0/bias*
validate_shape(*
_output_shapes
:@

down_level_1_no_0/bias/readIdentitydown_level_1_no_0/bias*
T0*)
_class
loc:@down_level_1_no_0/bias*
_output_shapes
:@
|
+down_level_1_no_0/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

down_level_1_no_0/convolutionConv2Dmax_0/MaxPooldown_level_1_no_0/kernel/read*
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@
У
down_level_1_no_0/BiasAddBiasAdddown_level_1_no_0/convolutiondown_level_1_no_0/bias/read*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@*
T0

down_level_1_no_0/ReluReludown_level_1_no_0/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@

&down_level_1_no_1/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"      @   @   
i
$down_level_1_no_1/random_uniform/minConst*
valueB
 *:ЭН*
dtype0*
_output_shapes
: 
i
$down_level_1_no_1/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *:Э=
Ф
.down_level_1_no_1/random_uniform/RandomUniformRandomUniform&down_level_1_no_1/random_uniform/shape*
seedБџх)*
T0*
dtype0*&
_output_shapes
:@@*
seed2ШЁњ

$down_level_1_no_1/random_uniform/subSub$down_level_1_no_1/random_uniform/max$down_level_1_no_1/random_uniform/min*
_output_shapes
: *
T0
В
$down_level_1_no_1/random_uniform/mulMul.down_level_1_no_1/random_uniform/RandomUniform$down_level_1_no_1/random_uniform/sub*
T0*&
_output_shapes
:@@
Є
 down_level_1_no_1/random_uniformAdd$down_level_1_no_1/random_uniform/mul$down_level_1_no_1/random_uniform/min*
T0*&
_output_shapes
:@@

down_level_1_no_1/kernel
VariableV2*
dtype0*&
_output_shapes
:@@*
	container *
shape:@@*
shared_name 
ь
down_level_1_no_1/kernel/AssignAssigndown_level_1_no_1/kernel down_level_1_no_1/random_uniform*
use_locking(*
T0*+
_class!
loc:@down_level_1_no_1/kernel*
validate_shape(*&
_output_shapes
:@@
Ё
down_level_1_no_1/kernel/readIdentitydown_level_1_no_1/kernel*&
_output_shapes
:@@*
T0*+
_class!
loc:@down_level_1_no_1/kernel
d
down_level_1_no_1/ConstConst*
valueB@*    *
dtype0*
_output_shapes
:@

down_level_1_no_1/bias
VariableV2*
shape:@*
shared_name *
dtype0*
_output_shapes
:@*
	container 
б
down_level_1_no_1/bias/AssignAssigndown_level_1_no_1/biasdown_level_1_no_1/Const*
use_locking(*
T0*)
_class
loc:@down_level_1_no_1/bias*
validate_shape(*
_output_shapes
:@

down_level_1_no_1/bias/readIdentitydown_level_1_no_1/bias*
T0*)
_class
loc:@down_level_1_no_1/bias*
_output_shapes
:@
|
+down_level_1_no_1/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

down_level_1_no_1/convolutionConv2Ddown_level_1_no_0/Reludown_level_1_no_1/kernel/read*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@*
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(
У
down_level_1_no_1/BiasAddBiasAdddown_level_1_no_1/convolutiondown_level_1_no_1/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@

down_level_1_no_1/ReluReludown_level_1_no_1/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@
Я
max_1/MaxPoolMaxPooldown_level_1_no_1/Relu*
ksize
*
paddingVALID*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@*
T0*
strides
*
data_formatNHWC

&down_level_2_no_0/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"      @      
i
$down_level_2_no_0/random_uniform/minConst*
valueB
 *я[qН*
dtype0*
_output_shapes
: 
i
$down_level_2_no_0/random_uniform/maxConst*
valueB
 *я[q=*
dtype0*
_output_shapes
: 
Х
.down_level_2_no_0/random_uniform/RandomUniformRandomUniform&down_level_2_no_0/random_uniform/shape*
dtype0*'
_output_shapes
:@*
seed2ЎІ*
seedБџх)*
T0

$down_level_2_no_0/random_uniform/subSub$down_level_2_no_0/random_uniform/max$down_level_2_no_0/random_uniform/min*
T0*
_output_shapes
: 
Г
$down_level_2_no_0/random_uniform/mulMul.down_level_2_no_0/random_uniform/RandomUniform$down_level_2_no_0/random_uniform/sub*
T0*'
_output_shapes
:@
Ѕ
 down_level_2_no_0/random_uniformAdd$down_level_2_no_0/random_uniform/mul$down_level_2_no_0/random_uniform/min*
T0*'
_output_shapes
:@

down_level_2_no_0/kernel
VariableV2*
dtype0*'
_output_shapes
:@*
	container *
shape:@*
shared_name 
э
down_level_2_no_0/kernel/AssignAssigndown_level_2_no_0/kernel down_level_2_no_0/random_uniform*
validate_shape(*'
_output_shapes
:@*
use_locking(*
T0*+
_class!
loc:@down_level_2_no_0/kernel
Ђ
down_level_2_no_0/kernel/readIdentitydown_level_2_no_0/kernel*'
_output_shapes
:@*
T0*+
_class!
loc:@down_level_2_no_0/kernel
f
down_level_2_no_0/ConstConst*
valueB*    *
dtype0*
_output_shapes	
:

down_level_2_no_0/bias
VariableV2*
dtype0*
_output_shapes	
:*
	container *
shape:*
shared_name 
в
down_level_2_no_0/bias/AssignAssigndown_level_2_no_0/biasdown_level_2_no_0/Const*
T0*)
_class
loc:@down_level_2_no_0/bias*
validate_shape(*
_output_shapes	
:*
use_locking(

down_level_2_no_0/bias/readIdentitydown_level_2_no_0/bias*
_output_shapes	
:*
T0*)
_class
loc:@down_level_2_no_0/bias
|
+down_level_2_no_0/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

down_level_2_no_0/convolutionConv2Dmax_1/MaxPooldown_level_2_no_0/kernel/read*
paddingSAME*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(
Ф
down_level_2_no_0/BiasAddBiasAdddown_level_2_no_0/convolutiondown_level_2_no_0/bias/read*
T0*
data_formatNHWC*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ

down_level_2_no_0/ReluReludown_level_2_no_0/BiasAdd*
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ

&down_level_2_no_1/random_uniform/shapeConst*%
valueB"            *
dtype0*
_output_shapes
:
i
$down_level_2_no_1/random_uniform/minConst*
valueB
 *ьQН*
dtype0*
_output_shapes
: 
i
$down_level_2_no_1/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *ьQ=
Ц
.down_level_2_no_1/random_uniform/RandomUniformRandomUniform&down_level_2_no_1/random_uniform/shape*
T0*
dtype0*(
_output_shapes
:*
seed2ћІ*
seedБџх)

$down_level_2_no_1/random_uniform/subSub$down_level_2_no_1/random_uniform/max$down_level_2_no_1/random_uniform/min*
T0*
_output_shapes
: 
Д
$down_level_2_no_1/random_uniform/mulMul.down_level_2_no_1/random_uniform/RandomUniform$down_level_2_no_1/random_uniform/sub*
T0*(
_output_shapes
:
І
 down_level_2_no_1/random_uniformAdd$down_level_2_no_1/random_uniform/mul$down_level_2_no_1/random_uniform/min*
T0*(
_output_shapes
:
 
down_level_2_no_1/kernel
VariableV2*
shared_name *
dtype0*(
_output_shapes
:*
	container *
shape:
ю
down_level_2_no_1/kernel/AssignAssigndown_level_2_no_1/kernel down_level_2_no_1/random_uniform*
use_locking(*
T0*+
_class!
loc:@down_level_2_no_1/kernel*
validate_shape(*(
_output_shapes
:
Ѓ
down_level_2_no_1/kernel/readIdentitydown_level_2_no_1/kernel*
T0*+
_class!
loc:@down_level_2_no_1/kernel*(
_output_shapes
:
f
down_level_2_no_1/ConstConst*
dtype0*
_output_shapes	
:*
valueB*    

down_level_2_no_1/bias
VariableV2*
shared_name *
dtype0*
_output_shapes	
:*
	container *
shape:
в
down_level_2_no_1/bias/AssignAssigndown_level_2_no_1/biasdown_level_2_no_1/Const*
validate_shape(*
_output_shapes	
:*
use_locking(*
T0*)
_class
loc:@down_level_2_no_1/bias

down_level_2_no_1/bias/readIdentitydown_level_2_no_1/bias*
T0*)
_class
loc:@down_level_2_no_1/bias*
_output_shapes	
:
|
+down_level_2_no_1/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      

down_level_2_no_1/convolutionConv2Ddown_level_2_no_0/Reludown_level_2_no_1/kernel/read*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME
Ф
down_level_2_no_1/BiasAddBiasAdddown_level_2_no_1/convolutiondown_level_2_no_1/bias/read*
T0*
data_formatNHWC*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ

down_level_2_no_1/ReluReludown_level_2_no_1/BiasAdd*
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
а
max_2/MaxPoolMaxPooldown_level_2_no_1/Relu*
data_formatNHWC*
strides
*
ksize
*
paddingVALID*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
T0
v
middle_0/random_uniform/shapeConst*%
valueB"            *
dtype0*
_output_shapes
:
`
middle_0/random_uniform/minConst*
valueB
 *ЋЊ*Н*
dtype0*
_output_shapes
: 
`
middle_0/random_uniform/maxConst*
valueB
 *ЋЊ*=*
dtype0*
_output_shapes
: 
Д
%middle_0/random_uniform/RandomUniformRandomUniformmiddle_0/random_uniform/shape*
dtype0*(
_output_shapes
:*
seed2ЎЦЉ*
seedБџх)*
T0
}
middle_0/random_uniform/subSubmiddle_0/random_uniform/maxmiddle_0/random_uniform/min*
_output_shapes
: *
T0

middle_0/random_uniform/mulMul%middle_0/random_uniform/RandomUniformmiddle_0/random_uniform/sub*
T0*(
_output_shapes
:

middle_0/random_uniformAddmiddle_0/random_uniform/mulmiddle_0/random_uniform/min*
T0*(
_output_shapes
:

middle_0/kernel
VariableV2*
dtype0*(
_output_shapes
:*
	container *
shape:*
shared_name 
Ъ
middle_0/kernel/AssignAssignmiddle_0/kernelmiddle_0/random_uniform*
T0*"
_class
loc:@middle_0/kernel*
validate_shape(*(
_output_shapes
:*
use_locking(

middle_0/kernel/readIdentitymiddle_0/kernel*(
_output_shapes
:*
T0*"
_class
loc:@middle_0/kernel
]
middle_0/ConstConst*
valueB*    *
dtype0*
_output_shapes	
:
{
middle_0/bias
VariableV2*
dtype0*
_output_shapes	
:*
	container *
shape:*
shared_name 
Ў
middle_0/bias/AssignAssignmiddle_0/biasmiddle_0/Const*
validate_shape(*
_output_shapes	
:*
use_locking(*
T0* 
_class
loc:@middle_0/bias
u
middle_0/bias/readIdentitymiddle_0/bias*
T0* 
_class
loc:@middle_0/bias*
_output_shapes	
:
s
"middle_0/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      
ў
middle_0/convolutionConv2Dmax_2/MaxPoolmiddle_0/kernel/read*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME
Љ
middle_0/BiasAddBiasAddmiddle_0/convolutionmiddle_0/bias/read*
data_formatNHWC*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
T0
t
middle_0/ReluRelumiddle_0/BiasAdd*
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
v
middle_2/random_uniform/shapeConst*%
valueB"            *
dtype0*
_output_shapes
:
`
middle_2/random_uniform/minConst*
dtype0*
_output_shapes
: *
valueB
 *ЋЊ*Н
`
middle_2/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *ЋЊ*=
Д
%middle_2/random_uniform/RandomUniformRandomUniformmiddle_2/random_uniform/shape*
seedБџх)*
T0*
dtype0*(
_output_shapes
:*
seed2хЙЬ
}
middle_2/random_uniform/subSubmiddle_2/random_uniform/maxmiddle_2/random_uniform/min*
_output_shapes
: *
T0

middle_2/random_uniform/mulMul%middle_2/random_uniform/RandomUniformmiddle_2/random_uniform/sub*(
_output_shapes
:*
T0

middle_2/random_uniformAddmiddle_2/random_uniform/mulmiddle_2/random_uniform/min*
T0*(
_output_shapes
:

middle_2/kernel
VariableV2*
dtype0*(
_output_shapes
:*
	container *
shape:*
shared_name 
Ъ
middle_2/kernel/AssignAssignmiddle_2/kernelmiddle_2/random_uniform*
T0*"
_class
loc:@middle_2/kernel*
validate_shape(*(
_output_shapes
:*
use_locking(

middle_2/kernel/readIdentitymiddle_2/kernel*
T0*"
_class
loc:@middle_2/kernel*(
_output_shapes
:
]
middle_2/ConstConst*
valueB*    *
dtype0*
_output_shapes	
:
{
middle_2/bias
VariableV2*
shared_name *
dtype0*
_output_shapes	
:*
	container *
shape:
Ў
middle_2/bias/AssignAssignmiddle_2/biasmiddle_2/Const*
use_locking(*
T0* 
_class
loc:@middle_2/bias*
validate_shape(*
_output_shapes	
:
u
middle_2/bias/readIdentitymiddle_2/bias*
T0* 
_class
loc:@middle_2/bias*
_output_shapes	
:
s
"middle_2/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      
ў
middle_2/convolutionConv2Dmiddle_0/Relumiddle_2/kernel/read*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
Љ
middle_2/BiasAddBiasAddmiddle_2/convolutionmiddle_2/bias/read*
T0*
data_formatNHWC*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
t
middle_2/ReluRelumiddle_2/BiasAdd*
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
b
up_sampling2d_1/ShapeShapemiddle_2/Relu*
T0*
out_type0*
_output_shapes
:
m
#up_sampling2d_1/strided_slice/stackConst*
valueB:*
dtype0*
_output_shapes
:
o
%up_sampling2d_1/strided_slice/stack_1Const*
valueB:*
dtype0*
_output_shapes
:
o
%up_sampling2d_1/strided_slice/stack_2Const*
valueB:*
dtype0*
_output_shapes
:
Э
up_sampling2d_1/strided_sliceStridedSliceup_sampling2d_1/Shape#up_sampling2d_1/strided_slice/stack%up_sampling2d_1/strided_slice/stack_1%up_sampling2d_1/strided_slice/stack_2*
Index0*
T0*
shrink_axis_mask *
ellipsis_mask *

begin_mask *
new_axis_mask *
end_mask *
_output_shapes
:
f
up_sampling2d_1/ConstConst*
valueB"      *
dtype0*
_output_shapes
:
u
up_sampling2d_1/mulMulup_sampling2d_1/strided_sliceup_sampling2d_1/Const*
_output_shapes
:*
T0
Ф
%up_sampling2d_1/ResizeNearestNeighborResizeNearestNeighbormiddle_2/Reluup_sampling2d_1/mul*
align_corners( *
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
[
concatenate_1/concat/axisConst*
value	B :*
dtype0*
_output_shapes
: 
м
concatenate_1/concatConcatV2%up_sampling2d_1/ResizeNearestNeighbordown_level_2_no_1/Reluconcatenate_1/concat/axis*
T0*
N*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*

Tidx0
}
$up_level_2_no_0/random_uniform/shapeConst*%
valueB"            *
dtype0*
_output_shapes
:
g
"up_level_2_no_0/random_uniform/minConst*
valueB
 *ЋЊ*Н*
dtype0*
_output_shapes
: 
g
"up_level_2_no_0/random_uniform/maxConst*
valueB
 *ЋЊ*=*
dtype0*
_output_shapes
: 
Т
,up_level_2_no_0/random_uniform/RandomUniformRandomUniform$up_level_2_no_0/random_uniform/shape*
T0*
dtype0*(
_output_shapes
:*
seed2В*
seedБџх)

"up_level_2_no_0/random_uniform/subSub"up_level_2_no_0/random_uniform/max"up_level_2_no_0/random_uniform/min*
_output_shapes
: *
T0
Ў
"up_level_2_no_0/random_uniform/mulMul,up_level_2_no_0/random_uniform/RandomUniform"up_level_2_no_0/random_uniform/sub*
T0*(
_output_shapes
:
 
up_level_2_no_0/random_uniformAdd"up_level_2_no_0/random_uniform/mul"up_level_2_no_0/random_uniform/min*
T0*(
_output_shapes
:

up_level_2_no_0/kernel
VariableV2*
shared_name *
dtype0*(
_output_shapes
:*
	container *
shape:
ц
up_level_2_no_0/kernel/AssignAssignup_level_2_no_0/kernelup_level_2_no_0/random_uniform*
T0*)
_class
loc:@up_level_2_no_0/kernel*
validate_shape(*(
_output_shapes
:*
use_locking(

up_level_2_no_0/kernel/readIdentityup_level_2_no_0/kernel*
T0*)
_class
loc:@up_level_2_no_0/kernel*(
_output_shapes
:
d
up_level_2_no_0/ConstConst*
valueB*    *
dtype0*
_output_shapes	
:

up_level_2_no_0/bias
VariableV2*
dtype0*
_output_shapes	
:*
	container *
shape:*
shared_name 
Ъ
up_level_2_no_0/bias/AssignAssignup_level_2_no_0/biasup_level_2_no_0/Const*
use_locking(*
T0*'
_class
loc:@up_level_2_no_0/bias*
validate_shape(*
_output_shapes	
:

up_level_2_no_0/bias/readIdentityup_level_2_no_0/bias*
T0*'
_class
loc:@up_level_2_no_0/bias*
_output_shapes	
:
z
)up_level_2_no_0/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

up_level_2_no_0/convolutionConv2Dconcatenate_1/concatup_level_2_no_0/kernel/read*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
О
up_level_2_no_0/BiasAddBiasAddup_level_2_no_0/convolutionup_level_2_no_0/bias/read*
T0*
data_formatNHWC*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ

up_level_2_no_0/ReluReluup_level_2_no_0/BiasAdd*
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
}
$up_level_2_no_2/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"         @   
g
"up_level_2_no_2/random_uniform/minConst*
valueB
 *я[qН*
dtype0*
_output_shapes
: 
g
"up_level_2_no_2/random_uniform/maxConst*
valueB
 *я[q=*
dtype0*
_output_shapes
: 
С
,up_level_2_no_2/random_uniform/RandomUniformRandomUniform$up_level_2_no_2/random_uniform/shape*
T0*
dtype0*'
_output_shapes
:@*
seed2лЈ*
seedБџх)

"up_level_2_no_2/random_uniform/subSub"up_level_2_no_2/random_uniform/max"up_level_2_no_2/random_uniform/min*
_output_shapes
: *
T0
­
"up_level_2_no_2/random_uniform/mulMul,up_level_2_no_2/random_uniform/RandomUniform"up_level_2_no_2/random_uniform/sub*
T0*'
_output_shapes
:@

up_level_2_no_2/random_uniformAdd"up_level_2_no_2/random_uniform/mul"up_level_2_no_2/random_uniform/min*
T0*'
_output_shapes
:@

up_level_2_no_2/kernel
VariableV2*
dtype0*'
_output_shapes
:@*
	container *
shape:@*
shared_name 
х
up_level_2_no_2/kernel/AssignAssignup_level_2_no_2/kernelup_level_2_no_2/random_uniform*
use_locking(*
T0*)
_class
loc:@up_level_2_no_2/kernel*
validate_shape(*'
_output_shapes
:@

up_level_2_no_2/kernel/readIdentityup_level_2_no_2/kernel*
T0*)
_class
loc:@up_level_2_no_2/kernel*'
_output_shapes
:@
b
up_level_2_no_2/ConstConst*
dtype0*
_output_shapes
:@*
valueB@*    

up_level_2_no_2/bias
VariableV2*
dtype0*
_output_shapes
:@*
	container *
shape:@*
shared_name 
Щ
up_level_2_no_2/bias/AssignAssignup_level_2_no_2/biasup_level_2_no_2/Const*
use_locking(*
T0*'
_class
loc:@up_level_2_no_2/bias*
validate_shape(*
_output_shapes
:@

up_level_2_no_2/bias/readIdentityup_level_2_no_2/bias*
T0*'
_class
loc:@up_level_2_no_2/bias*
_output_shapes
:@
z
)up_level_2_no_2/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      

up_level_2_no_2/convolutionConv2Dup_level_2_no_0/Reluup_level_2_no_2/kernel/read*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@
Н
up_level_2_no_2/BiasAddBiasAddup_level_2_no_2/convolutionup_level_2_no_2/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@

up_level_2_no_2/ReluReluup_level_2_no_2/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@
i
up_sampling2d_2/ShapeShapeup_level_2_no_2/Relu*
T0*
out_type0*
_output_shapes
:
m
#up_sampling2d_2/strided_slice/stackConst*
dtype0*
_output_shapes
:*
valueB:
o
%up_sampling2d_2/strided_slice/stack_1Const*
valueB:*
dtype0*
_output_shapes
:
o
%up_sampling2d_2/strided_slice/stack_2Const*
valueB:*
dtype0*
_output_shapes
:
Э
up_sampling2d_2/strided_sliceStridedSliceup_sampling2d_2/Shape#up_sampling2d_2/strided_slice/stack%up_sampling2d_2/strided_slice/stack_1%up_sampling2d_2/strided_slice/stack_2*
shrink_axis_mask *
ellipsis_mask *

begin_mask *
new_axis_mask *
end_mask *
_output_shapes
:*
Index0*
T0
f
up_sampling2d_2/ConstConst*
valueB"      *
dtype0*
_output_shapes
:
u
up_sampling2d_2/mulMulup_sampling2d_2/strided_sliceup_sampling2d_2/Const*
T0*
_output_shapes
:
Ъ
%up_sampling2d_2/ResizeNearestNeighborResizeNearestNeighborup_level_2_no_2/Reluup_sampling2d_2/mul*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@*
align_corners( 
[
concatenate_2/concat/axisConst*
value	B :*
dtype0*
_output_shapes
: 
м
concatenate_2/concatConcatV2%up_sampling2d_2/ResizeNearestNeighbordown_level_1_no_1/Reluconcatenate_2/concat/axis*
T0*
N*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*

Tidx0
}
$up_level_1_no_0/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"         @   
g
"up_level_1_no_0/random_uniform/minConst*
dtype0*
_output_shapes
: *
valueB
 *я[qН
g
"up_level_1_no_0/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *я[q=
С
,up_level_1_no_0/random_uniform/RandomUniformRandomUniform$up_level_1_no_0/random_uniform/shape*
T0*
dtype0*'
_output_shapes
:@*
seed2ЏГЃ*
seedБџх)

"up_level_1_no_0/random_uniform/subSub"up_level_1_no_0/random_uniform/max"up_level_1_no_0/random_uniform/min*
T0*
_output_shapes
: 
­
"up_level_1_no_0/random_uniform/mulMul,up_level_1_no_0/random_uniform/RandomUniform"up_level_1_no_0/random_uniform/sub*
T0*'
_output_shapes
:@

up_level_1_no_0/random_uniformAdd"up_level_1_no_0/random_uniform/mul"up_level_1_no_0/random_uniform/min*'
_output_shapes
:@*
T0

up_level_1_no_0/kernel
VariableV2*
shape:@*
shared_name *
dtype0*'
_output_shapes
:@*
	container 
х
up_level_1_no_0/kernel/AssignAssignup_level_1_no_0/kernelup_level_1_no_0/random_uniform*
use_locking(*
T0*)
_class
loc:@up_level_1_no_0/kernel*
validate_shape(*'
_output_shapes
:@

up_level_1_no_0/kernel/readIdentityup_level_1_no_0/kernel*
T0*)
_class
loc:@up_level_1_no_0/kernel*'
_output_shapes
:@
b
up_level_1_no_0/ConstConst*
valueB@*    *
dtype0*
_output_shapes
:@

up_level_1_no_0/bias
VariableV2*
shape:@*
shared_name *
dtype0*
_output_shapes
:@*
	container 
Щ
up_level_1_no_0/bias/AssignAssignup_level_1_no_0/biasup_level_1_no_0/Const*
T0*'
_class
loc:@up_level_1_no_0/bias*
validate_shape(*
_output_shapes
:@*
use_locking(

up_level_1_no_0/bias/readIdentityup_level_1_no_0/bias*
T0*'
_class
loc:@up_level_1_no_0/bias*
_output_shapes
:@
z
)up_level_1_no_0/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      

up_level_1_no_0/convolutionConv2Dconcatenate_2/concatup_level_1_no_0/kernel/read*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(
Н
up_level_1_no_0/BiasAddBiasAddup_level_1_no_0/convolutionup_level_1_no_0/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@

up_level_1_no_0/ReluReluup_level_1_no_0/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@
}
$up_level_1_no_2/random_uniform/shapeConst*%
valueB"      @       *
dtype0*
_output_shapes
:
g
"up_level_1_no_2/random_uniform/minConst*
dtype0*
_output_shapes
: *
valueB
 *ЋЊЊН
g
"up_level_1_no_2/random_uniform/maxConst*
valueB
 *ЋЊЊ=*
dtype0*
_output_shapes
: 
Р
,up_level_1_no_2/random_uniform/RandomUniformRandomUniform$up_level_1_no_2/random_uniform/shape*
seedБџх)*
T0*
dtype0*&
_output_shapes
:@ *
seed2ЌФ

"up_level_1_no_2/random_uniform/subSub"up_level_1_no_2/random_uniform/max"up_level_1_no_2/random_uniform/min*
T0*
_output_shapes
: 
Ќ
"up_level_1_no_2/random_uniform/mulMul,up_level_1_no_2/random_uniform/RandomUniform"up_level_1_no_2/random_uniform/sub*
T0*&
_output_shapes
:@ 

up_level_1_no_2/random_uniformAdd"up_level_1_no_2/random_uniform/mul"up_level_1_no_2/random_uniform/min*
T0*&
_output_shapes
:@ 

up_level_1_no_2/kernel
VariableV2*
shared_name *
dtype0*&
_output_shapes
:@ *
	container *
shape:@ 
ф
up_level_1_no_2/kernel/AssignAssignup_level_1_no_2/kernelup_level_1_no_2/random_uniform*
use_locking(*
T0*)
_class
loc:@up_level_1_no_2/kernel*
validate_shape(*&
_output_shapes
:@ 

up_level_1_no_2/kernel/readIdentityup_level_1_no_2/kernel*
T0*)
_class
loc:@up_level_1_no_2/kernel*&
_output_shapes
:@ 
b
up_level_1_no_2/ConstConst*
valueB *    *
dtype0*
_output_shapes
: 

up_level_1_no_2/bias
VariableV2*
shape: *
shared_name *
dtype0*
_output_shapes
: *
	container 
Щ
up_level_1_no_2/bias/AssignAssignup_level_1_no_2/biasup_level_1_no_2/Const*
use_locking(*
T0*'
_class
loc:@up_level_1_no_2/bias*
validate_shape(*
_output_shapes
: 

up_level_1_no_2/bias/readIdentityup_level_1_no_2/bias*
T0*'
_class
loc:@up_level_1_no_2/bias*
_output_shapes
: 
z
)up_level_1_no_2/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      

up_level_1_no_2/convolutionConv2Dup_level_1_no_0/Reluup_level_1_no_2/kernel/read*
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
Н
up_level_1_no_2/BiasAddBiasAddup_level_1_no_2/convolutionup_level_1_no_2/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 

up_level_1_no_2/ReluReluup_level_1_no_2/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
i
up_sampling2d_3/ShapeShapeup_level_1_no_2/Relu*
_output_shapes
:*
T0*
out_type0
m
#up_sampling2d_3/strided_slice/stackConst*
valueB:*
dtype0*
_output_shapes
:
o
%up_sampling2d_3/strided_slice/stack_1Const*
valueB:*
dtype0*
_output_shapes
:
o
%up_sampling2d_3/strided_slice/stack_2Const*
valueB:*
dtype0*
_output_shapes
:
Э
up_sampling2d_3/strided_sliceStridedSliceup_sampling2d_3/Shape#up_sampling2d_3/strided_slice/stack%up_sampling2d_3/strided_slice/stack_1%up_sampling2d_3/strided_slice/stack_2*
shrink_axis_mask *

begin_mask *
ellipsis_mask *
new_axis_mask *
end_mask *
_output_shapes
:*
Index0*
T0
f
up_sampling2d_3/ConstConst*
dtype0*
_output_shapes
:*
valueB"      
u
up_sampling2d_3/mulMulup_sampling2d_3/strided_sliceup_sampling2d_3/Const*
T0*
_output_shapes
:
Ъ
%up_sampling2d_3/ResizeNearestNeighborResizeNearestNeighborup_level_1_no_2/Reluup_sampling2d_3/mul*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
align_corners( *
T0
[
concatenate_3/concat/axisConst*
value	B :*
dtype0*
_output_shapes
: 
л
concatenate_3/concatConcatV2%up_sampling2d_3/ResizeNearestNeighbordown_level_0_no_1/Reluconcatenate_3/concat/axis*
T0*
N*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ@*

Tidx0
}
$up_level_0_no_0/random_uniform/shapeConst*%
valueB"      @       *
dtype0*
_output_shapes
:
g
"up_level_0_no_0/random_uniform/minConst*
valueB
 *ЋЊЊН*
dtype0*
_output_shapes
: 
g
"up_level_0_no_0/random_uniform/maxConst*
valueB
 *ЋЊЊ=*
dtype0*
_output_shapes
: 
Р
,up_level_0_no_0/random_uniform/RandomUniformRandomUniform$up_level_0_no_0/random_uniform/shape*
T0*
dtype0*&
_output_shapes
:@ *
seed2ЉЖд*
seedБџх)

"up_level_0_no_0/random_uniform/subSub"up_level_0_no_0/random_uniform/max"up_level_0_no_0/random_uniform/min*
_output_shapes
: *
T0
Ќ
"up_level_0_no_0/random_uniform/mulMul,up_level_0_no_0/random_uniform/RandomUniform"up_level_0_no_0/random_uniform/sub*
T0*&
_output_shapes
:@ 

up_level_0_no_0/random_uniformAdd"up_level_0_no_0/random_uniform/mul"up_level_0_no_0/random_uniform/min*
T0*&
_output_shapes
:@ 

up_level_0_no_0/kernel
VariableV2*
dtype0*&
_output_shapes
:@ *
	container *
shape:@ *
shared_name 
ф
up_level_0_no_0/kernel/AssignAssignup_level_0_no_0/kernelup_level_0_no_0/random_uniform*
use_locking(*
T0*)
_class
loc:@up_level_0_no_0/kernel*
validate_shape(*&
_output_shapes
:@ 

up_level_0_no_0/kernel/readIdentityup_level_0_no_0/kernel*
T0*)
_class
loc:@up_level_0_no_0/kernel*&
_output_shapes
:@ 
b
up_level_0_no_0/ConstConst*
valueB *    *
dtype0*
_output_shapes
: 

up_level_0_no_0/bias
VariableV2*
shared_name *
dtype0*
_output_shapes
: *
	container *
shape: 
Щ
up_level_0_no_0/bias/AssignAssignup_level_0_no_0/biasup_level_0_no_0/Const*
use_locking(*
T0*'
_class
loc:@up_level_0_no_0/bias*
validate_shape(*
_output_shapes
: 

up_level_0_no_0/bias/readIdentityup_level_0_no_0/bias*
T0*'
_class
loc:@up_level_0_no_0/bias*
_output_shapes
: 
z
)up_level_0_no_0/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

up_level_0_no_0/convolutionConv2Dconcatenate_3/concatup_level_0_no_0/kernel/read*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations
*
T0
Н
up_level_0_no_0/BiasAddBiasAddup_level_0_no_0/convolutionup_level_0_no_0/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 

up_level_0_no_0/ReluReluup_level_0_no_0/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
}
$up_level_0_no_2/random_uniform/shapeConst*%
valueB"              *
dtype0*
_output_shapes
:
g
"up_level_0_no_2/random_uniform/minConst*
valueB
 *ьбН*
dtype0*
_output_shapes
: 
g
"up_level_0_no_2/random_uniform/maxConst*
valueB
 *ьб=*
dtype0*
_output_shapes
: 
П
,up_level_0_no_2/random_uniform/RandomUniformRandomUniform$up_level_0_no_2/random_uniform/shape*
T0*
dtype0*&
_output_shapes
:  *
seed2№­p*
seedБџх)

"up_level_0_no_2/random_uniform/subSub"up_level_0_no_2/random_uniform/max"up_level_0_no_2/random_uniform/min*
T0*
_output_shapes
: 
Ќ
"up_level_0_no_2/random_uniform/mulMul,up_level_0_no_2/random_uniform/RandomUniform"up_level_0_no_2/random_uniform/sub*
T0*&
_output_shapes
:  

up_level_0_no_2/random_uniformAdd"up_level_0_no_2/random_uniform/mul"up_level_0_no_2/random_uniform/min*&
_output_shapes
:  *
T0

up_level_0_no_2/kernel
VariableV2*
dtype0*&
_output_shapes
:  *
	container *
shape:  *
shared_name 
ф
up_level_0_no_2/kernel/AssignAssignup_level_0_no_2/kernelup_level_0_no_2/random_uniform*
use_locking(*
T0*)
_class
loc:@up_level_0_no_2/kernel*
validate_shape(*&
_output_shapes
:  

up_level_0_no_2/kernel/readIdentityup_level_0_no_2/kernel*
T0*)
_class
loc:@up_level_0_no_2/kernel*&
_output_shapes
:  
b
up_level_0_no_2/ConstConst*
dtype0*
_output_shapes
: *
valueB *    

up_level_0_no_2/bias
VariableV2*
dtype0*
_output_shapes
: *
	container *
shape: *
shared_name 
Щ
up_level_0_no_2/bias/AssignAssignup_level_0_no_2/biasup_level_0_no_2/Const*
use_locking(*
T0*'
_class
loc:@up_level_0_no_2/bias*
validate_shape(*
_output_shapes
: 

up_level_0_no_2/bias/readIdentityup_level_0_no_2/bias*
T0*'
_class
loc:@up_level_0_no_2/bias*
_output_shapes
: 
z
)up_level_0_no_2/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

up_level_0_no_2/convolutionConv2Dup_level_0_no_0/Reluup_level_0_no_2/kernel/read*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(
Н
up_level_0_no_2/BiasAddBiasAddup_level_0_no_2/convolutionup_level_0_no_2/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 

up_level_0_no_2/ReluReluup_level_0_no_2/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
v
features/random_uniform/shapeConst*%
valueB"             *
dtype0*
_output_shapes
:
`
features/random_uniform/minConst*
valueB
 *Ѕ2Н*
dtype0*
_output_shapes
: 
`
features/random_uniform/maxConst*
dtype0*
_output_shapes
: *
valueB
 *Ѕ2=
Г
%features/random_uniform/RandomUniformRandomUniformfeatures/random_uniform/shape*
seedБџх)*
T0*
dtype0*'
_output_shapes
: *
seed2ї
}
features/random_uniform/subSubfeatures/random_uniform/maxfeatures/random_uniform/min*
T0*
_output_shapes
: 

features/random_uniform/mulMul%features/random_uniform/RandomUniformfeatures/random_uniform/sub*
T0*'
_output_shapes
: 

features/random_uniformAddfeatures/random_uniform/mulfeatures/random_uniform/min*'
_output_shapes
: *
T0

features/kernel
VariableV2*
shared_name *
dtype0*'
_output_shapes
: *
	container *
shape: 
Щ
features/kernel/AssignAssignfeatures/kernelfeatures/random_uniform*
use_locking(*
T0*"
_class
loc:@features/kernel*
validate_shape(*'
_output_shapes
: 

features/kernel/readIdentityfeatures/kernel*'
_output_shapes
: *
T0*"
_class
loc:@features/kernel
]
features/ConstConst*
dtype0*
_output_shapes	
:*
valueB*    
{
features/bias
VariableV2*
shared_name *
dtype0*
_output_shapes	
:*
	container *
shape:
Ў
features/bias/AssignAssignfeatures/biasfeatures/Const*
T0* 
_class
loc:@features/bias*
validate_shape(*
_output_shapes	
:*
use_locking(
u
features/bias/readIdentityfeatures/bias*
_output_shapes	
:*
T0* 
_class
loc:@features/bias
s
"features/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:

features/convolutionConv2Dup_level_0_no_2/Relufeatures/kernel/read*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
	dilations
*
T0*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME
Љ
features/BiasAddBiasAddfeatures/convolutionfeatures/bias/read*
T0*
data_formatNHWC*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
t
features/ReluRelufeatures/BiasAdd*
T0*B
_output_shapes0
.:,џџџџџџџџџџџџџџџџџџџџџџџџџџџ
r
prob/random_uniform/shapeConst*
dtype0*
_output_shapes
:*%
valueB"            
\
prob/random_uniform/minConst*
dtype0*
_output_shapes
: *
valueB
 *nз\О
\
prob/random_uniform/maxConst*
valueB
 *nз\>*
dtype0*
_output_shapes
: 
Ћ
!prob/random_uniform/RandomUniformRandomUniformprob/random_uniform/shape*
T0*
dtype0*'
_output_shapes
:*
seed2Жљ*
seedБџх)
q
prob/random_uniform/subSubprob/random_uniform/maxprob/random_uniform/min*
T0*
_output_shapes
: 

prob/random_uniform/mulMul!prob/random_uniform/RandomUniformprob/random_uniform/sub*
T0*'
_output_shapes
:
~
prob/random_uniformAddprob/random_uniform/mulprob/random_uniform/min*'
_output_shapes
:*
T0

prob/kernel
VariableV2*
dtype0*'
_output_shapes
:*
	container *
shape:*
shared_name 
Й
prob/kernel/AssignAssignprob/kernelprob/random_uniform*
validate_shape(*'
_output_shapes
:*
use_locking(*
T0*
_class
loc:@prob/kernel
{
prob/kernel/readIdentityprob/kernel*
T0*
_class
loc:@prob/kernel*'
_output_shapes
:
W

prob/ConstConst*
valueB*    *
dtype0*
_output_shapes
:
u
	prob/bias
VariableV2*
dtype0*
_output_shapes
:*
	container *
shape:*
shared_name 

prob/bias/AssignAssign	prob/bias
prob/Const*
T0*
_class
loc:@prob/bias*
validate_shape(*
_output_shapes
:*
use_locking(
h
prob/bias/readIdentity	prob/bias*
T0*
_class
loc:@prob/bias*
_output_shapes
:
o
prob/convolution/dilation_rateConst*
valueB"      *
dtype0*
_output_shapes
:
ѕ
prob/convolutionConv2Dfeatures/Reluprob/kernel/read*
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ

prob/BiasAddBiasAddprob/convolutionprob/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ
q
prob/SigmoidSigmoidprob/BiasAdd*
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ
r
dist/random_uniform/shapeConst*%
valueB"             *
dtype0*
_output_shapes
:
\
dist/random_uniform/minConst*
valueB
 *јKFО*
dtype0*
_output_shapes
: 
\
dist/random_uniform/maxConst*
valueB
 *јKF>*
dtype0*
_output_shapes
: 
Ћ
!dist/random_uniform/RandomUniformRandomUniformdist/random_uniform/shape*
dtype0*'
_output_shapes
: *
seed2Ђ*
seedБџх)*
T0
q
dist/random_uniform/subSubdist/random_uniform/maxdist/random_uniform/min*
T0*
_output_shapes
: 

dist/random_uniform/mulMul!dist/random_uniform/RandomUniformdist/random_uniform/sub*
T0*'
_output_shapes
: 
~
dist/random_uniformAdddist/random_uniform/muldist/random_uniform/min*'
_output_shapes
: *
T0

dist/kernel
VariableV2*
dtype0*'
_output_shapes
: *
	container *
shape: *
shared_name 
Й
dist/kernel/AssignAssigndist/kerneldist/random_uniform*
use_locking(*
T0*
_class
loc:@dist/kernel*
validate_shape(*'
_output_shapes
: 
{
dist/kernel/readIdentitydist/kernel*
T0*
_class
loc:@dist/kernel*'
_output_shapes
: 
W

dist/ConstConst*
dtype0*
_output_shapes
: *
valueB *    
u
	dist/bias
VariableV2*
dtype0*
_output_shapes
: *
	container *
shape: *
shared_name 

dist/bias/AssignAssign	dist/bias
dist/Const*
T0*
_class
loc:@dist/bias*
validate_shape(*
_output_shapes
: *
use_locking(
h
dist/bias/readIdentity	dist/bias*
T0*
_class
loc:@dist/bias*
_output_shapes
: 
o
dist/convolution/dilation_rateConst*
dtype0*
_output_shapes
:*
valueB"      
ѕ
dist/convolutionConv2Dfeatures/Reludist/kernel/read*
strides
*
data_formatNHWC*
use_cudnn_on_gpu(*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ *
	dilations
*
T0

dist/BiasAddBiasAdddist/convolutiondist/bias/read*
T0*
data_formatNHWC*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
l
PlaceholderPlaceholder*
dtype0*&
_output_shapes
: *
shape: 
Ќ
AssignAssignconv2d_1/kernelPlaceholder*
T0*"
_class
loc:@conv2d_1/kernel*
validate_shape(*&
_output_shapes
: *
use_locking( 
V
Placeholder_1Placeholder*
dtype0*
_output_shapes
: *
shape: 
 
Assign_1Assignconv2d_1/biasPlaceholder_1*
validate_shape(*
_output_shapes
: *
use_locking( *
T0* 
_class
loc:@conv2d_1/bias
n
Placeholder_2Placeholder*
shape:  *
dtype0*&
_output_shapes
:  
А
Assign_2Assignconv2d_2/kernelPlaceholder_2*
use_locking( *
T0*"
_class
loc:@conv2d_2/kernel*
validate_shape(*&
_output_shapes
:  
V
Placeholder_3Placeholder*
dtype0*
_output_shapes
: *
shape: 
 
Assign_3Assignconv2d_2/biasPlaceholder_3*
use_locking( *
T0* 
_class
loc:@conv2d_2/bias*
validate_shape(*
_output_shapes
: 
n
Placeholder_4Placeholder*
dtype0*&
_output_shapes
:  *
shape:  
Т
Assign_4Assigndown_level_0_no_0/kernelPlaceholder_4*
use_locking( *
T0*+
_class!
loc:@down_level_0_no_0/kernel*
validate_shape(*&
_output_shapes
:  
V
Placeholder_5Placeholder*
shape: *
dtype0*
_output_shapes
: 
В
Assign_5Assigndown_level_0_no_0/biasPlaceholder_5*
validate_shape(*
_output_shapes
: *
use_locking( *
T0*)
_class
loc:@down_level_0_no_0/bias
n
Placeholder_6Placeholder*
shape:  *
dtype0*&
_output_shapes
:  
Т
Assign_6Assigndown_level_0_no_1/kernelPlaceholder_6*
use_locking( *
T0*+
_class!
loc:@down_level_0_no_1/kernel*
validate_shape(*&
_output_shapes
:  
V
Placeholder_7Placeholder*
dtype0*
_output_shapes
: *
shape: 
В
Assign_7Assigndown_level_0_no_1/biasPlaceholder_7*
T0*)
_class
loc:@down_level_0_no_1/bias*
validate_shape(*
_output_shapes
: *
use_locking( 
n
Placeholder_8Placeholder*
dtype0*&
_output_shapes
: @*
shape: @
Т
Assign_8Assigndown_level_1_no_0/kernelPlaceholder_8*
T0*+
_class!
loc:@down_level_1_no_0/kernel*
validate_shape(*&
_output_shapes
: @*
use_locking( 
V
Placeholder_9Placeholder*
shape:@*
dtype0*
_output_shapes
:@
В
Assign_9Assigndown_level_1_no_0/biasPlaceholder_9*
use_locking( *
T0*)
_class
loc:@down_level_1_no_0/bias*
validate_shape(*
_output_shapes
:@
o
Placeholder_10Placeholder*
dtype0*&
_output_shapes
:@@*
shape:@@
Ф
	Assign_10Assigndown_level_1_no_1/kernelPlaceholder_10*
use_locking( *
T0*+
_class!
loc:@down_level_1_no_1/kernel*
validate_shape(*&
_output_shapes
:@@
W
Placeholder_11Placeholder*
shape:@*
dtype0*
_output_shapes
:@
Д
	Assign_11Assigndown_level_1_no_1/biasPlaceholder_11*
T0*)
_class
loc:@down_level_1_no_1/bias*
validate_shape(*
_output_shapes
:@*
use_locking( 
q
Placeholder_12Placeholder*
dtype0*'
_output_shapes
:@*
shape:@
Х
	Assign_12Assigndown_level_2_no_0/kernelPlaceholder_12*
use_locking( *
T0*+
_class!
loc:@down_level_2_no_0/kernel*
validate_shape(*'
_output_shapes
:@
Y
Placeholder_13Placeholder*
dtype0*
_output_shapes	
:*
shape:
Е
	Assign_13Assigndown_level_2_no_0/biasPlaceholder_13*
validate_shape(*
_output_shapes	
:*
use_locking( *
T0*)
_class
loc:@down_level_2_no_0/bias
s
Placeholder_14Placeholder*
dtype0*(
_output_shapes
:*
shape:
Ц
	Assign_14Assigndown_level_2_no_1/kernelPlaceholder_14*
validate_shape(*(
_output_shapes
:*
use_locking( *
T0*+
_class!
loc:@down_level_2_no_1/kernel
Y
Placeholder_15Placeholder*
dtype0*
_output_shapes	
:*
shape:
Е
	Assign_15Assigndown_level_2_no_1/biasPlaceholder_15*
use_locking( *
T0*)
_class
loc:@down_level_2_no_1/bias*
validate_shape(*
_output_shapes	
:
s
Placeholder_16Placeholder*
dtype0*(
_output_shapes
:*
shape:
Д
	Assign_16Assignmiddle_0/kernelPlaceholder_16*
use_locking( *
T0*"
_class
loc:@middle_0/kernel*
validate_shape(*(
_output_shapes
:
Y
Placeholder_17Placeholder*
dtype0*
_output_shapes	
:*
shape:
Ѓ
	Assign_17Assignmiddle_0/biasPlaceholder_17*
T0* 
_class
loc:@middle_0/bias*
validate_shape(*
_output_shapes	
:*
use_locking( 
s
Placeholder_18Placeholder*
dtype0*(
_output_shapes
:*
shape:
Д
	Assign_18Assignmiddle_2/kernelPlaceholder_18*
validate_shape(*(
_output_shapes
:*
use_locking( *
T0*"
_class
loc:@middle_2/kernel
Y
Placeholder_19Placeholder*
shape:*
dtype0*
_output_shapes	
:
Ѓ
	Assign_19Assignmiddle_2/biasPlaceholder_19*
use_locking( *
T0* 
_class
loc:@middle_2/bias*
validate_shape(*
_output_shapes	
:
s
Placeholder_20Placeholder*
shape:*
dtype0*(
_output_shapes
:
Т
	Assign_20Assignup_level_2_no_0/kernelPlaceholder_20*
validate_shape(*(
_output_shapes
:*
use_locking( *
T0*)
_class
loc:@up_level_2_no_0/kernel
Y
Placeholder_21Placeholder*
shape:*
dtype0*
_output_shapes	
:
Б
	Assign_21Assignup_level_2_no_0/biasPlaceholder_21*
use_locking( *
T0*'
_class
loc:@up_level_2_no_0/bias*
validate_shape(*
_output_shapes	
:
q
Placeholder_22Placeholder*
dtype0*'
_output_shapes
:@*
shape:@
С
	Assign_22Assignup_level_2_no_2/kernelPlaceholder_22*
T0*)
_class
loc:@up_level_2_no_2/kernel*
validate_shape(*'
_output_shapes
:@*
use_locking( 
W
Placeholder_23Placeholder*
dtype0*
_output_shapes
:@*
shape:@
А
	Assign_23Assignup_level_2_no_2/biasPlaceholder_23*
use_locking( *
T0*'
_class
loc:@up_level_2_no_2/bias*
validate_shape(*
_output_shapes
:@
q
Placeholder_24Placeholder*
dtype0*'
_output_shapes
:@*
shape:@
С
	Assign_24Assignup_level_1_no_0/kernelPlaceholder_24*
use_locking( *
T0*)
_class
loc:@up_level_1_no_0/kernel*
validate_shape(*'
_output_shapes
:@
W
Placeholder_25Placeholder*
dtype0*
_output_shapes
:@*
shape:@
А
	Assign_25Assignup_level_1_no_0/biasPlaceholder_25*
validate_shape(*
_output_shapes
:@*
use_locking( *
T0*'
_class
loc:@up_level_1_no_0/bias
o
Placeholder_26Placeholder*
dtype0*&
_output_shapes
:@ *
shape:@ 
Р
	Assign_26Assignup_level_1_no_2/kernelPlaceholder_26*
validate_shape(*&
_output_shapes
:@ *
use_locking( *
T0*)
_class
loc:@up_level_1_no_2/kernel
W
Placeholder_27Placeholder*
dtype0*
_output_shapes
: *
shape: 
А
	Assign_27Assignup_level_1_no_2/biasPlaceholder_27*
validate_shape(*
_output_shapes
: *
use_locking( *
T0*'
_class
loc:@up_level_1_no_2/bias
o
Placeholder_28Placeholder*
dtype0*&
_output_shapes
:@ *
shape:@ 
Р
	Assign_28Assignup_level_0_no_0/kernelPlaceholder_28*
use_locking( *
T0*)
_class
loc:@up_level_0_no_0/kernel*
validate_shape(*&
_output_shapes
:@ 
W
Placeholder_29Placeholder*
dtype0*
_output_shapes
: *
shape: 
А
	Assign_29Assignup_level_0_no_0/biasPlaceholder_29*
use_locking( *
T0*'
_class
loc:@up_level_0_no_0/bias*
validate_shape(*
_output_shapes
: 
o
Placeholder_30Placeholder*
dtype0*&
_output_shapes
:  *
shape:  
Р
	Assign_30Assignup_level_0_no_2/kernelPlaceholder_30*
use_locking( *
T0*)
_class
loc:@up_level_0_no_2/kernel*
validate_shape(*&
_output_shapes
:  
W
Placeholder_31Placeholder*
dtype0*
_output_shapes
: *
shape: 
А
	Assign_31Assignup_level_0_no_2/biasPlaceholder_31*
use_locking( *
T0*'
_class
loc:@up_level_0_no_2/bias*
validate_shape(*
_output_shapes
: 
q
Placeholder_32Placeholder*
shape: *
dtype0*'
_output_shapes
: 
Г
	Assign_32Assignfeatures/kernelPlaceholder_32*
validate_shape(*'
_output_shapes
: *
use_locking( *
T0*"
_class
loc:@features/kernel
Y
Placeholder_33Placeholder*
shape:*
dtype0*
_output_shapes	
:
Ѓ
	Assign_33Assignfeatures/biasPlaceholder_33*
use_locking( *
T0* 
_class
loc:@features/bias*
validate_shape(*
_output_shapes	
:
q
Placeholder_34Placeholder*
shape:*
dtype0*'
_output_shapes
:
Ћ
	Assign_34Assignprob/kernelPlaceholder_34*
use_locking( *
T0*
_class
loc:@prob/kernel*
validate_shape(*'
_output_shapes
:
W
Placeholder_35Placeholder*
dtype0*
_output_shapes
:*
shape:

	Assign_35Assign	prob/biasPlaceholder_35*
T0*
_class
loc:@prob/bias*
validate_shape(*
_output_shapes
:*
use_locking( 
q
Placeholder_36Placeholder*
shape: *
dtype0*'
_output_shapes
: 
Ћ
	Assign_36Assigndist/kernelPlaceholder_36*
validate_shape(*'
_output_shapes
: *
use_locking( *
T0*
_class
loc:@dist/kernel
W
Placeholder_37Placeholder*
dtype0*
_output_shapes
: *
shape: 

	Assign_37Assign	dist/biasPlaceholder_37*
use_locking( *
T0*
_class
loc:@dist/bias*
validate_shape(*
_output_shapes
: 

IsVariableInitializedIsVariableInitializedconv2d_1/kernel*
dtype0*
_output_shapes
: *"
_class
loc:@conv2d_1/kernel

IsVariableInitialized_1IsVariableInitializedconv2d_1/bias* 
_class
loc:@conv2d_1/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_2IsVariableInitializedconv2d_2/kernel*"
_class
loc:@conv2d_2/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_3IsVariableInitializedconv2d_2/bias* 
_class
loc:@conv2d_2/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_4IsVariableInitializeddown_level_0_no_0/kernel*+
_class!
loc:@down_level_0_no_0/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_5IsVariableInitializeddown_level_0_no_0/bias*)
_class
loc:@down_level_0_no_0/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_6IsVariableInitializeddown_level_0_no_1/kernel*+
_class!
loc:@down_level_0_no_1/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_7IsVariableInitializeddown_level_0_no_1/bias*)
_class
loc:@down_level_0_no_1/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_8IsVariableInitializeddown_level_1_no_0/kernel*+
_class!
loc:@down_level_1_no_0/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_9IsVariableInitializeddown_level_1_no_0/bias*)
_class
loc:@down_level_1_no_0/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_10IsVariableInitializeddown_level_1_no_1/kernel*+
_class!
loc:@down_level_1_no_1/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_11IsVariableInitializeddown_level_1_no_1/bias*
dtype0*
_output_shapes
: *)
_class
loc:@down_level_1_no_1/bias

IsVariableInitialized_12IsVariableInitializeddown_level_2_no_0/kernel*+
_class!
loc:@down_level_2_no_0/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_13IsVariableInitializeddown_level_2_no_0/bias*)
_class
loc:@down_level_2_no_0/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_14IsVariableInitializeddown_level_2_no_1/kernel*+
_class!
loc:@down_level_2_no_1/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_15IsVariableInitializeddown_level_2_no_1/bias*)
_class
loc:@down_level_2_no_1/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_16IsVariableInitializedmiddle_0/kernel*
dtype0*
_output_shapes
: *"
_class
loc:@middle_0/kernel

IsVariableInitialized_17IsVariableInitializedmiddle_0/bias*
dtype0*
_output_shapes
: * 
_class
loc:@middle_0/bias

IsVariableInitialized_18IsVariableInitializedmiddle_2/kernel*
dtype0*
_output_shapes
: *"
_class
loc:@middle_2/kernel

IsVariableInitialized_19IsVariableInitializedmiddle_2/bias* 
_class
loc:@middle_2/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_20IsVariableInitializedup_level_2_no_0/kernel*)
_class
loc:@up_level_2_no_0/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_21IsVariableInitializedup_level_2_no_0/bias*
dtype0*
_output_shapes
: *'
_class
loc:@up_level_2_no_0/bias

IsVariableInitialized_22IsVariableInitializedup_level_2_no_2/kernel*)
_class
loc:@up_level_2_no_2/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_23IsVariableInitializedup_level_2_no_2/bias*'
_class
loc:@up_level_2_no_2/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_24IsVariableInitializedup_level_1_no_0/kernel*)
_class
loc:@up_level_1_no_0/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_25IsVariableInitializedup_level_1_no_0/bias*'
_class
loc:@up_level_1_no_0/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_26IsVariableInitializedup_level_1_no_2/kernel*)
_class
loc:@up_level_1_no_2/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_27IsVariableInitializedup_level_1_no_2/bias*'
_class
loc:@up_level_1_no_2/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_28IsVariableInitializedup_level_0_no_0/kernel*)
_class
loc:@up_level_0_no_0/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_29IsVariableInitializedup_level_0_no_0/bias*'
_class
loc:@up_level_0_no_0/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_30IsVariableInitializedup_level_0_no_2/kernel*
dtype0*
_output_shapes
: *)
_class
loc:@up_level_0_no_2/kernel

IsVariableInitialized_31IsVariableInitializedup_level_0_no_2/bias*'
_class
loc:@up_level_0_no_2/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_32IsVariableInitializedfeatures/kernel*"
_class
loc:@features/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_33IsVariableInitializedfeatures/bias* 
_class
loc:@features/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_34IsVariableInitializedprob/kernel*
_class
loc:@prob/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_35IsVariableInitialized	prob/bias*
_class
loc:@prob/bias*
dtype0*
_output_shapes
: 

IsVariableInitialized_36IsVariableInitializeddist/kernel*
_class
loc:@dist/kernel*
dtype0*
_output_shapes
: 

IsVariableInitialized_37IsVariableInitialized	dist/bias*
_class
loc:@dist/bias*
dtype0*
_output_shapes
: 
Ь
initNoOp^conv2d_1/bias/Assign^conv2d_1/kernel/Assign^conv2d_2/bias/Assign^conv2d_2/kernel/Assign^dist/bias/Assign^dist/kernel/Assign^down_level_0_no_0/bias/Assign ^down_level_0_no_0/kernel/Assign^down_level_0_no_1/bias/Assign ^down_level_0_no_1/kernel/Assign^down_level_1_no_0/bias/Assign ^down_level_1_no_0/kernel/Assign^down_level_1_no_1/bias/Assign ^down_level_1_no_1/kernel/Assign^down_level_2_no_0/bias/Assign ^down_level_2_no_0/kernel/Assign^down_level_2_no_1/bias/Assign ^down_level_2_no_1/kernel/Assign^features/bias/Assign^features/kernel/Assign^middle_0/bias/Assign^middle_0/kernel/Assign^middle_2/bias/Assign^middle_2/kernel/Assign^prob/bias/Assign^prob/kernel/Assign^up_level_0_no_0/bias/Assign^up_level_0_no_0/kernel/Assign^up_level_0_no_2/bias/Assign^up_level_0_no_2/kernel/Assign^up_level_1_no_0/bias/Assign^up_level_1_no_0/kernel/Assign^up_level_1_no_2/bias/Assign^up_level_1_no_2/kernel/Assign^up_level_2_no_0/bias/Assign^up_level_2_no_0/kernel/Assign^up_level_2_no_2/bias/Assign^up_level_2_no_2/kernel/Assign
}
conv2d_transpose_1/ConstConst*
dtype0*&
_output_shapes
:*%
valueB*  ?

conv2d_transpose_1/kernel
VariableV2*
dtype0*&
_output_shapes
:*
	container *
shape:*
shared_name 
ч
 conv2d_transpose_1/kernel/AssignAssignconv2d_transpose_1/kernelconv2d_transpose_1/Const*
T0*,
_class"
 loc:@conv2d_transpose_1/kernel*
validate_shape(*&
_output_shapes
:*
use_locking(
Є
conv2d_transpose_1/kernel/readIdentityconv2d_transpose_1/kernel*
T0*,
_class"
 loc:@conv2d_transpose_1/kernel*&
_output_shapes
:
d
conv2d_transpose_1/ShapeShapeprob/Sigmoid*
_output_shapes
:*
T0*
out_type0
p
&conv2d_transpose_1/strided_slice/stackConst*
valueB: *
dtype0*
_output_shapes
:
r
(conv2d_transpose_1/strided_slice/stack_1Const*
valueB:*
dtype0*
_output_shapes
:
r
(conv2d_transpose_1/strided_slice/stack_2Const*
valueB:*
dtype0*
_output_shapes
:
и
 conv2d_transpose_1/strided_sliceStridedSliceconv2d_transpose_1/Shape&conv2d_transpose_1/strided_slice/stack(conv2d_transpose_1/strided_slice/stack_1(conv2d_transpose_1/strided_slice/stack_2*
T0*
Index0*
shrink_axis_mask*
ellipsis_mask *

begin_mask *
new_axis_mask *
end_mask *
_output_shapes
: 
r
(conv2d_transpose_1/strided_slice_1/stackConst*
valueB:*
dtype0*
_output_shapes
:
t
*conv2d_transpose_1/strided_slice_1/stack_1Const*
dtype0*
_output_shapes
:*
valueB:
t
*conv2d_transpose_1/strided_slice_1/stack_2Const*
valueB:*
dtype0*
_output_shapes
:
р
"conv2d_transpose_1/strided_slice_1StridedSliceconv2d_transpose_1/Shape(conv2d_transpose_1/strided_slice_1/stack*conv2d_transpose_1/strided_slice_1/stack_1*conv2d_transpose_1/strided_slice_1/stack_2*

begin_mask *
ellipsis_mask *
new_axis_mask *
end_mask *
_output_shapes
: *
Index0*
T0*
shrink_axis_mask
r
(conv2d_transpose_1/strided_slice_2/stackConst*
valueB:*
dtype0*
_output_shapes
:
t
*conv2d_transpose_1/strided_slice_2/stack_1Const*
valueB:*
dtype0*
_output_shapes
:
t
*conv2d_transpose_1/strided_slice_2/stack_2Const*
valueB:*
dtype0*
_output_shapes
:
р
"conv2d_transpose_1/strided_slice_2StridedSliceconv2d_transpose_1/Shape(conv2d_transpose_1/strided_slice_2/stack*conv2d_transpose_1/strided_slice_2/stack_1*conv2d_transpose_1/strided_slice_2/stack_2*
shrink_axis_mask*
ellipsis_mask *

begin_mask *
new_axis_mask *
end_mask *
_output_shapes
: *
T0*
Index0
Z
conv2d_transpose_1/mul/yConst*
value	B :*
dtype0*
_output_shapes
: 
|
conv2d_transpose_1/mulMul"conv2d_transpose_1/strided_slice_1conv2d_transpose_1/mul/y*
_output_shapes
: *
T0
\
conv2d_transpose_1/mul_1/yConst*
value	B :*
dtype0*
_output_shapes
: 

conv2d_transpose_1/mul_1Mul"conv2d_transpose_1/strided_slice_2conv2d_transpose_1/mul_1/y*
T0*
_output_shapes
: 
\
conv2d_transpose_1/stack/3Const*
value	B :*
dtype0*
_output_shapes
: 
Ъ
conv2d_transpose_1/stackPack conv2d_transpose_1/strided_sliceconv2d_transpose_1/mulconv2d_transpose_1/mul_1conv2d_transpose_1/stack/3*
T0*

axis *
N*
_output_shapes
:
r
(conv2d_transpose_1/strided_slice_3/stackConst*
valueB: *
dtype0*
_output_shapes
:
t
*conv2d_transpose_1/strided_slice_3/stack_1Const*
dtype0*
_output_shapes
:*
valueB:
t
*conv2d_transpose_1/strided_slice_3/stack_2Const*
dtype0*
_output_shapes
:*
valueB:
р
"conv2d_transpose_1/strided_slice_3StridedSliceconv2d_transpose_1/stack(conv2d_transpose_1/strided_slice_3/stack*conv2d_transpose_1/strided_slice_3/stack_1*conv2d_transpose_1/strided_slice_3/stack_2*
T0*
Index0*
shrink_axis_mask*

begin_mask *
ellipsis_mask *
new_axis_mask *
end_mask *
_output_shapes
: 
М
#conv2d_transpose_1/conv2d_transposeConv2DBackpropInputconv2d_transpose_1/stackconv2d_transpose_1/kernel/readprob/Sigmoid*
paddingSAME*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ*
	dilations
*
T0*
data_formatNHWC*
strides
*
use_cudnn_on_gpu(
a
up_sampling2d_4/ShapeShapedist/BiasAdd*
T0*
out_type0*
_output_shapes
:
m
#up_sampling2d_4/strided_slice/stackConst*
valueB:*
dtype0*
_output_shapes
:
o
%up_sampling2d_4/strided_slice/stack_1Const*
dtype0*
_output_shapes
:*
valueB:
o
%up_sampling2d_4/strided_slice/stack_2Const*
dtype0*
_output_shapes
:*
valueB:
Э
up_sampling2d_4/strided_sliceStridedSliceup_sampling2d_4/Shape#up_sampling2d_4/strided_slice/stack%up_sampling2d_4/strided_slice/stack_1%up_sampling2d_4/strided_slice/stack_2*
end_mask *
_output_shapes
:*
T0*
Index0*
shrink_axis_mask *

begin_mask *
ellipsis_mask *
new_axis_mask 
f
up_sampling2d_4/ConstConst*
valueB"      *
dtype0*
_output_shapes
:
u
up_sampling2d_4/mulMulup_sampling2d_4/strided_sliceup_sampling2d_4/Const*
T0*
_output_shapes
:
Т
%up_sampling2d_4/ResizeNearestNeighborResizeNearestNeighbordist/BiasAddup_sampling2d_4/mul*
align_corners( *
T0*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ 
[
concatenate_4/concat/axisConst*
value	B :*
dtype0*
_output_shapes
: 
ш
concatenate_4/concatConcatV2#conv2d_transpose_1/conv2d_transpose%up_sampling2d_4/ResizeNearestNeighborconcatenate_4/concat/axis*
T0*
N*A
_output_shapes/
-:+џџџџџџџџџџџџџџџџџџџџџџџџџџџ!*

Tidx0

IsVariableInitialized_38IsVariableInitializedconv2d_transpose_1/kernel*,
_class"
 loc:@conv2d_transpose_1/kernel*
dtype0*
_output_shapes
: 
1
init_1NoOp!^conv2d_transpose_1/kernel/Assign
P

save/ConstConst*
dtype0*
_output_shapes
: *
valueB Bmodel

save/StringJoin/inputs_1Const*<
value3B1 B+_temp_138c49c5287e480d9b92a40adfdcaa1d/part*
dtype0*
_output_shapes
: 
u
save/StringJoin
StringJoin
save/Constsave/StringJoin/inputs_1*
N*
_output_shapes
: *
	separator 
Q
save/num_shardsConst*
value	B :*
dtype0*
_output_shapes
: 
k
save/ShardedFilename/shardConst"/device:CPU:0*
value	B : *
dtype0*
_output_shapes
: 

save/ShardedFilenameShardedFilenamesave/StringJoinsave/ShardedFilename/shardsave/num_shards"/device:CPU:0*
_output_shapes
: 

save/SaveV2/tensor_namesConst"/device:CPU:0*Р
valueЖBГ'Bconv2d_1/biasBconv2d_1/kernelBconv2d_2/biasBconv2d_2/kernelBconv2d_transpose_1/kernelB	dist/biasBdist/kernelBdown_level_0_no_0/biasBdown_level_0_no_0/kernelBdown_level_0_no_1/biasBdown_level_0_no_1/kernelBdown_level_1_no_0/biasBdown_level_1_no_0/kernelBdown_level_1_no_1/biasBdown_level_1_no_1/kernelBdown_level_2_no_0/biasBdown_level_2_no_0/kernelBdown_level_2_no_1/biasBdown_level_2_no_1/kernelBfeatures/biasBfeatures/kernelBmiddle_0/biasBmiddle_0/kernelBmiddle_2/biasBmiddle_2/kernelB	prob/biasBprob/kernelBup_level_0_no_0/biasBup_level_0_no_0/kernelBup_level_0_no_2/biasBup_level_0_no_2/kernelBup_level_1_no_0/biasBup_level_1_no_0/kernelBup_level_1_no_2/biasBup_level_1_no_2/kernelBup_level_2_no_0/biasBup_level_2_no_0/kernelBup_level_2_no_2/biasBup_level_2_no_2/kernel*
dtype0*
_output_shapes
:'
Р
save/SaveV2/shape_and_slicesConst"/device:CPU:0*a
valueXBV'B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B *
dtype0*
_output_shapes
:'
д
save/SaveV2SaveV2save/ShardedFilenamesave/SaveV2/tensor_namessave/SaveV2/shape_and_slicesconv2d_1/biasconv2d_1/kernelconv2d_2/biasconv2d_2/kernelconv2d_transpose_1/kernel	dist/biasdist/kerneldown_level_0_no_0/biasdown_level_0_no_0/kerneldown_level_0_no_1/biasdown_level_0_no_1/kerneldown_level_1_no_0/biasdown_level_1_no_0/kerneldown_level_1_no_1/biasdown_level_1_no_1/kerneldown_level_2_no_0/biasdown_level_2_no_0/kerneldown_level_2_no_1/biasdown_level_2_no_1/kernelfeatures/biasfeatures/kernelmiddle_0/biasmiddle_0/kernelmiddle_2/biasmiddle_2/kernel	prob/biasprob/kernelup_level_0_no_0/biasup_level_0_no_0/kernelup_level_0_no_2/biasup_level_0_no_2/kernelup_level_1_no_0/biasup_level_1_no_0/kernelup_level_1_no_2/biasup_level_1_no_2/kernelup_level_2_no_0/biasup_level_2_no_0/kernelup_level_2_no_2/biasup_level_2_no_2/kernel"/device:CPU:0*5
dtypes+
)2'
 
save/control_dependencyIdentitysave/ShardedFilename^save/SaveV2"/device:CPU:0*
T0*'
_class
loc:@save/ShardedFilename*
_output_shapes
: 
Ќ
+save/MergeV2Checkpoints/checkpoint_prefixesPacksave/ShardedFilename^save/control_dependency"/device:CPU:0*
T0*

axis *
N*
_output_shapes
:

save/MergeV2CheckpointsMergeV2Checkpoints+save/MergeV2Checkpoints/checkpoint_prefixes
save/Const"/device:CPU:0*
delete_old_dirs(

save/IdentityIdentity
save/Const^save/MergeV2Checkpoints^save/control_dependency"/device:CPU:0*
_output_shapes
: *
T0

save/RestoreV2/tensor_namesConst"/device:CPU:0*Р
valueЖBГ'Bconv2d_1/biasBconv2d_1/kernelBconv2d_2/biasBconv2d_2/kernelBconv2d_transpose_1/kernelB	dist/biasBdist/kernelBdown_level_0_no_0/biasBdown_level_0_no_0/kernelBdown_level_0_no_1/biasBdown_level_0_no_1/kernelBdown_level_1_no_0/biasBdown_level_1_no_0/kernelBdown_level_1_no_1/biasBdown_level_1_no_1/kernelBdown_level_2_no_0/biasBdown_level_2_no_0/kernelBdown_level_2_no_1/biasBdown_level_2_no_1/kernelBfeatures/biasBfeatures/kernelBmiddle_0/biasBmiddle_0/kernelBmiddle_2/biasBmiddle_2/kernelB	prob/biasBprob/kernelBup_level_0_no_0/biasBup_level_0_no_0/kernelBup_level_0_no_2/biasBup_level_0_no_2/kernelBup_level_1_no_0/biasBup_level_1_no_0/kernelBup_level_1_no_2/biasBup_level_1_no_2/kernelBup_level_2_no_0/biasBup_level_2_no_0/kernelBup_level_2_no_2/biasBup_level_2_no_2/kernel*
dtype0*
_output_shapes
:'
У
save/RestoreV2/shape_and_slicesConst"/device:CPU:0*a
valueXBV'B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B *
dtype0*
_output_shapes
:'
р
save/RestoreV2	RestoreV2
save/Constsave/RestoreV2/tensor_namessave/RestoreV2/shape_and_slices"/device:CPU:0*В
_output_shapes
:::::::::::::::::::::::::::::::::::::::*5
dtypes+
)2'
Є
save/AssignAssignconv2d_1/biassave/RestoreV2*
T0* 
_class
loc:@conv2d_1/bias*
validate_shape(*
_output_shapes
: *
use_locking(
И
save/Assign_1Assignconv2d_1/kernelsave/RestoreV2:1*
T0*"
_class
loc:@conv2d_1/kernel*
validate_shape(*&
_output_shapes
: *
use_locking(
Ј
save/Assign_2Assignconv2d_2/biassave/RestoreV2:2*
validate_shape(*
_output_shapes
: *
use_locking(*
T0* 
_class
loc:@conv2d_2/bias
И
save/Assign_3Assignconv2d_2/kernelsave/RestoreV2:3*
use_locking(*
T0*"
_class
loc:@conv2d_2/kernel*
validate_shape(*&
_output_shapes
:  
Ь
save/Assign_4Assignconv2d_transpose_1/kernelsave/RestoreV2:4*
use_locking(*
T0*,
_class"
 loc:@conv2d_transpose_1/kernel*
validate_shape(*&
_output_shapes
:
 
save/Assign_5Assign	dist/biassave/RestoreV2:5*
T0*
_class
loc:@dist/bias*
validate_shape(*
_output_shapes
: *
use_locking(
Б
save/Assign_6Assigndist/kernelsave/RestoreV2:6*
T0*
_class
loc:@dist/kernel*
validate_shape(*'
_output_shapes
: *
use_locking(
К
save/Assign_7Assigndown_level_0_no_0/biassave/RestoreV2:7*
validate_shape(*
_output_shapes
: *
use_locking(*
T0*)
_class
loc:@down_level_0_no_0/bias
Ъ
save/Assign_8Assigndown_level_0_no_0/kernelsave/RestoreV2:8*
use_locking(*
T0*+
_class!
loc:@down_level_0_no_0/kernel*
validate_shape(*&
_output_shapes
:  
К
save/Assign_9Assigndown_level_0_no_1/biassave/RestoreV2:9*
T0*)
_class
loc:@down_level_0_no_1/bias*
validate_shape(*
_output_shapes
: *
use_locking(
Ь
save/Assign_10Assigndown_level_0_no_1/kernelsave/RestoreV2:10*
use_locking(*
T0*+
_class!
loc:@down_level_0_no_1/kernel*
validate_shape(*&
_output_shapes
:  
М
save/Assign_11Assigndown_level_1_no_0/biassave/RestoreV2:11*
use_locking(*
T0*)
_class
loc:@down_level_1_no_0/bias*
validate_shape(*
_output_shapes
:@
Ь
save/Assign_12Assigndown_level_1_no_0/kernelsave/RestoreV2:12*
T0*+
_class!
loc:@down_level_1_no_0/kernel*
validate_shape(*&
_output_shapes
: @*
use_locking(
М
save/Assign_13Assigndown_level_1_no_1/biassave/RestoreV2:13*
use_locking(*
T0*)
_class
loc:@down_level_1_no_1/bias*
validate_shape(*
_output_shapes
:@
Ь
save/Assign_14Assigndown_level_1_no_1/kernelsave/RestoreV2:14*
T0*+
_class!
loc:@down_level_1_no_1/kernel*
validate_shape(*&
_output_shapes
:@@*
use_locking(
Н
save/Assign_15Assigndown_level_2_no_0/biassave/RestoreV2:15*
validate_shape(*
_output_shapes	
:*
use_locking(*
T0*)
_class
loc:@down_level_2_no_0/bias
Э
save/Assign_16Assigndown_level_2_no_0/kernelsave/RestoreV2:16*
use_locking(*
T0*+
_class!
loc:@down_level_2_no_0/kernel*
validate_shape(*'
_output_shapes
:@
Н
save/Assign_17Assigndown_level_2_no_1/biassave/RestoreV2:17*
use_locking(*
T0*)
_class
loc:@down_level_2_no_1/bias*
validate_shape(*
_output_shapes	
:
Ю
save/Assign_18Assigndown_level_2_no_1/kernelsave/RestoreV2:18*
use_locking(*
T0*+
_class!
loc:@down_level_2_no_1/kernel*
validate_shape(*(
_output_shapes
:
Ћ
save/Assign_19Assignfeatures/biassave/RestoreV2:19*
use_locking(*
T0* 
_class
loc:@features/bias*
validate_shape(*
_output_shapes	
:
Л
save/Assign_20Assignfeatures/kernelsave/RestoreV2:20*
use_locking(*
T0*"
_class
loc:@features/kernel*
validate_shape(*'
_output_shapes
: 
Ћ
save/Assign_21Assignmiddle_0/biassave/RestoreV2:21*
use_locking(*
T0* 
_class
loc:@middle_0/bias*
validate_shape(*
_output_shapes	
:
М
save/Assign_22Assignmiddle_0/kernelsave/RestoreV2:22*
T0*"
_class
loc:@middle_0/kernel*
validate_shape(*(
_output_shapes
:*
use_locking(
Ћ
save/Assign_23Assignmiddle_2/biassave/RestoreV2:23*
use_locking(*
T0* 
_class
loc:@middle_2/bias*
validate_shape(*
_output_shapes	
:
М
save/Assign_24Assignmiddle_2/kernelsave/RestoreV2:24*
use_locking(*
T0*"
_class
loc:@middle_2/kernel*
validate_shape(*(
_output_shapes
:
Ђ
save/Assign_25Assign	prob/biassave/RestoreV2:25*
T0*
_class
loc:@prob/bias*
validate_shape(*
_output_shapes
:*
use_locking(
Г
save/Assign_26Assignprob/kernelsave/RestoreV2:26*
use_locking(*
T0*
_class
loc:@prob/kernel*
validate_shape(*'
_output_shapes
:
И
save/Assign_27Assignup_level_0_no_0/biassave/RestoreV2:27*
use_locking(*
T0*'
_class
loc:@up_level_0_no_0/bias*
validate_shape(*
_output_shapes
: 
Ш
save/Assign_28Assignup_level_0_no_0/kernelsave/RestoreV2:28*
use_locking(*
T0*)
_class
loc:@up_level_0_no_0/kernel*
validate_shape(*&
_output_shapes
:@ 
И
save/Assign_29Assignup_level_0_no_2/biassave/RestoreV2:29*
validate_shape(*
_output_shapes
: *
use_locking(*
T0*'
_class
loc:@up_level_0_no_2/bias
Ш
save/Assign_30Assignup_level_0_no_2/kernelsave/RestoreV2:30*
use_locking(*
T0*)
_class
loc:@up_level_0_no_2/kernel*
validate_shape(*&
_output_shapes
:  
И
save/Assign_31Assignup_level_1_no_0/biassave/RestoreV2:31*
validate_shape(*
_output_shapes
:@*
use_locking(*
T0*'
_class
loc:@up_level_1_no_0/bias
Щ
save/Assign_32Assignup_level_1_no_0/kernelsave/RestoreV2:32*
use_locking(*
T0*)
_class
loc:@up_level_1_no_0/kernel*
validate_shape(*'
_output_shapes
:@
И
save/Assign_33Assignup_level_1_no_2/biassave/RestoreV2:33*
validate_shape(*
_output_shapes
: *
use_locking(*
T0*'
_class
loc:@up_level_1_no_2/bias
Ш
save/Assign_34Assignup_level_1_no_2/kernelsave/RestoreV2:34*
use_locking(*
T0*)
_class
loc:@up_level_1_no_2/kernel*
validate_shape(*&
_output_shapes
:@ 
Й
save/Assign_35Assignup_level_2_no_0/biassave/RestoreV2:35*
validate_shape(*
_output_shapes	
:*
use_locking(*
T0*'
_class
loc:@up_level_2_no_0/bias
Ъ
save/Assign_36Assignup_level_2_no_0/kernelsave/RestoreV2:36*
use_locking(*
T0*)
_class
loc:@up_level_2_no_0/kernel*
validate_shape(*(
_output_shapes
:
И
save/Assign_37Assignup_level_2_no_2/biassave/RestoreV2:37*
T0*'
_class
loc:@up_level_2_no_2/bias*
validate_shape(*
_output_shapes
:@*
use_locking(
Щ
save/Assign_38Assignup_level_2_no_2/kernelsave/RestoreV2:38*
validate_shape(*'
_output_shapes
:@*
use_locking(*
T0*)
_class
loc:@up_level_2_no_2/kernel
Ѕ
save/restore_shardNoOp^save/Assign^save/Assign_1^save/Assign_10^save/Assign_11^save/Assign_12^save/Assign_13^save/Assign_14^save/Assign_15^save/Assign_16^save/Assign_17^save/Assign_18^save/Assign_19^save/Assign_2^save/Assign_20^save/Assign_21^save/Assign_22^save/Assign_23^save/Assign_24^save/Assign_25^save/Assign_26^save/Assign_27^save/Assign_28^save/Assign_29^save/Assign_3^save/Assign_30^save/Assign_31^save/Assign_32^save/Assign_33^save/Assign_34^save/Assign_35^save/Assign_36^save/Assign_37^save/Assign_38^save/Assign_4^save/Assign_5^save/Assign_6^save/Assign_7^save/Assign_8^save/Assign_9
-
save/restore_allNoOp^save/restore_shard"<
save/Const:0save/Identity:0save/restore_all (5 @F8"б!
trainable_variablesЙ!Ж!
`
conv2d_1/kernel:0conv2d_1/kernel/Assignconv2d_1/kernel/read:02conv2d_1/random_uniform:08
Q
conv2d_1/bias:0conv2d_1/bias/Assignconv2d_1/bias/read:02conv2d_1/Const:08
`
conv2d_2/kernel:0conv2d_2/kernel/Assignconv2d_2/kernel/read:02conv2d_2/random_uniform:08
Q
conv2d_2/bias:0conv2d_2/bias/Assignconv2d_2/bias/read:02conv2d_2/Const:08

down_level_0_no_0/kernel:0down_level_0_no_0/kernel/Assigndown_level_0_no_0/kernel/read:02"down_level_0_no_0/random_uniform:08
u
down_level_0_no_0/bias:0down_level_0_no_0/bias/Assigndown_level_0_no_0/bias/read:02down_level_0_no_0/Const:08

down_level_0_no_1/kernel:0down_level_0_no_1/kernel/Assigndown_level_0_no_1/kernel/read:02"down_level_0_no_1/random_uniform:08
u
down_level_0_no_1/bias:0down_level_0_no_1/bias/Assigndown_level_0_no_1/bias/read:02down_level_0_no_1/Const:08

down_level_1_no_0/kernel:0down_level_1_no_0/kernel/Assigndown_level_1_no_0/kernel/read:02"down_level_1_no_0/random_uniform:08
u
down_level_1_no_0/bias:0down_level_1_no_0/bias/Assigndown_level_1_no_0/bias/read:02down_level_1_no_0/Const:08

down_level_1_no_1/kernel:0down_level_1_no_1/kernel/Assigndown_level_1_no_1/kernel/read:02"down_level_1_no_1/random_uniform:08
u
down_level_1_no_1/bias:0down_level_1_no_1/bias/Assigndown_level_1_no_1/bias/read:02down_level_1_no_1/Const:08

down_level_2_no_0/kernel:0down_level_2_no_0/kernel/Assigndown_level_2_no_0/kernel/read:02"down_level_2_no_0/random_uniform:08
u
down_level_2_no_0/bias:0down_level_2_no_0/bias/Assigndown_level_2_no_0/bias/read:02down_level_2_no_0/Const:08

down_level_2_no_1/kernel:0down_level_2_no_1/kernel/Assigndown_level_2_no_1/kernel/read:02"down_level_2_no_1/random_uniform:08
u
down_level_2_no_1/bias:0down_level_2_no_1/bias/Assigndown_level_2_no_1/bias/read:02down_level_2_no_1/Const:08
`
middle_0/kernel:0middle_0/kernel/Assignmiddle_0/kernel/read:02middle_0/random_uniform:08
Q
middle_0/bias:0middle_0/bias/Assignmiddle_0/bias/read:02middle_0/Const:08
`
middle_2/kernel:0middle_2/kernel/Assignmiddle_2/kernel/read:02middle_2/random_uniform:08
Q
middle_2/bias:0middle_2/bias/Assignmiddle_2/bias/read:02middle_2/Const:08
|
up_level_2_no_0/kernel:0up_level_2_no_0/kernel/Assignup_level_2_no_0/kernel/read:02 up_level_2_no_0/random_uniform:08
m
up_level_2_no_0/bias:0up_level_2_no_0/bias/Assignup_level_2_no_0/bias/read:02up_level_2_no_0/Const:08
|
up_level_2_no_2/kernel:0up_level_2_no_2/kernel/Assignup_level_2_no_2/kernel/read:02 up_level_2_no_2/random_uniform:08
m
up_level_2_no_2/bias:0up_level_2_no_2/bias/Assignup_level_2_no_2/bias/read:02up_level_2_no_2/Const:08
|
up_level_1_no_0/kernel:0up_level_1_no_0/kernel/Assignup_level_1_no_0/kernel/read:02 up_level_1_no_0/random_uniform:08
m
up_level_1_no_0/bias:0up_level_1_no_0/bias/Assignup_level_1_no_0/bias/read:02up_level_1_no_0/Const:08
|
up_level_1_no_2/kernel:0up_level_1_no_2/kernel/Assignup_level_1_no_2/kernel/read:02 up_level_1_no_2/random_uniform:08
m
up_level_1_no_2/bias:0up_level_1_no_2/bias/Assignup_level_1_no_2/bias/read:02up_level_1_no_2/Const:08
|
up_level_0_no_0/kernel:0up_level_0_no_0/kernel/Assignup_level_0_no_0/kernel/read:02 up_level_0_no_0/random_uniform:08
m
up_level_0_no_0/bias:0up_level_0_no_0/bias/Assignup_level_0_no_0/bias/read:02up_level_0_no_0/Const:08
|
up_level_0_no_2/kernel:0up_level_0_no_2/kernel/Assignup_level_0_no_2/kernel/read:02 up_level_0_no_2/random_uniform:08
m
up_level_0_no_2/bias:0up_level_0_no_2/bias/Assignup_level_0_no_2/bias/read:02up_level_0_no_2/Const:08
`
features/kernel:0features/kernel/Assignfeatures/kernel/read:02features/random_uniform:08
Q
features/bias:0features/bias/Assignfeatures/bias/read:02features/Const:08
P
prob/kernel:0prob/kernel/Assignprob/kernel/read:02prob/random_uniform:08
A
prob/bias:0prob/bias/Assignprob/bias/read:02prob/Const:08
P
dist/kernel:0dist/kernel/Assigndist/kernel/read:02dist/random_uniform:08
A
dist/bias:0dist/bias/Assigndist/bias/read:02dist/Const:08

conv2d_transpose_1/kernel:0 conv2d_transpose_1/kernel/Assign conv2d_transpose_1/kernel/read:02conv2d_transpose_1/Const:08"Ч!
	variablesЙ!Ж!
`
conv2d_1/kernel:0conv2d_1/kernel/Assignconv2d_1/kernel/read:02conv2d_1/random_uniform:08
Q
conv2d_1/bias:0conv2d_1/bias/Assignconv2d_1/bias/read:02conv2d_1/Const:08
`
conv2d_2/kernel:0conv2d_2/kernel/Assignconv2d_2/kernel/read:02conv2d_2/random_uniform:08
Q
conv2d_2/bias:0conv2d_2/bias/Assignconv2d_2/bias/read:02conv2d_2/Const:08

down_level_0_no_0/kernel:0down_level_0_no_0/kernel/Assigndown_level_0_no_0/kernel/read:02"down_level_0_no_0/random_uniform:08
u
down_level_0_no_0/bias:0down_level_0_no_0/bias/Assigndown_level_0_no_0/bias/read:02down_level_0_no_0/Const:08

down_level_0_no_1/kernel:0down_level_0_no_1/kernel/Assigndown_level_0_no_1/kernel/read:02"down_level_0_no_1/random_uniform:08
u
down_level_0_no_1/bias:0down_level_0_no_1/bias/Assigndown_level_0_no_1/bias/read:02down_level_0_no_1/Const:08

down_level_1_no_0/kernel:0down_level_1_no_0/kernel/Assigndown_level_1_no_0/kernel/read:02"down_level_1_no_0/random_uniform:08
u
down_level_1_no_0/bias:0down_level_1_no_0/bias/Assigndown_level_1_no_0/bias/read:02down_level_1_no_0/Const:08

down_level_1_no_1/kernel:0down_level_1_no_1/kernel/Assigndown_level_1_no_1/kernel/read:02"down_level_1_no_1/random_uniform:08
u
down_level_1_no_1/bias:0down_level_1_no_1/bias/Assigndown_level_1_no_1/bias/read:02down_level_1_no_1/Const:08

down_level_2_no_0/kernel:0down_level_2_no_0/kernel/Assigndown_level_2_no_0/kernel/read:02"down_level_2_no_0/random_uniform:08
u
down_level_2_no_0/bias:0down_level_2_no_0/bias/Assigndown_level_2_no_0/bias/read:02down_level_2_no_0/Const:08

down_level_2_no_1/kernel:0down_level_2_no_1/kernel/Assigndown_level_2_no_1/kernel/read:02"down_level_2_no_1/random_uniform:08
u
down_level_2_no_1/bias:0down_level_2_no_1/bias/Assigndown_level_2_no_1/bias/read:02down_level_2_no_1/Const:08
`
middle_0/kernel:0middle_0/kernel/Assignmiddle_0/kernel/read:02middle_0/random_uniform:08
Q
middle_0/bias:0middle_0/bias/Assignmiddle_0/bias/read:02middle_0/Const:08
`
middle_2/kernel:0middle_2/kernel/Assignmiddle_2/kernel/read:02middle_2/random_uniform:08
Q
middle_2/bias:0middle_2/bias/Assignmiddle_2/bias/read:02middle_2/Const:08
|
up_level_2_no_0/kernel:0up_level_2_no_0/kernel/Assignup_level_2_no_0/kernel/read:02 up_level_2_no_0/random_uniform:08
m
up_level_2_no_0/bias:0up_level_2_no_0/bias/Assignup_level_2_no_0/bias/read:02up_level_2_no_0/Const:08
|
up_level_2_no_2/kernel:0up_level_2_no_2/kernel/Assignup_level_2_no_2/kernel/read:02 up_level_2_no_2/random_uniform:08
m
up_level_2_no_2/bias:0up_level_2_no_2/bias/Assignup_level_2_no_2/bias/read:02up_level_2_no_2/Const:08
|
up_level_1_no_0/kernel:0up_level_1_no_0/kernel/Assignup_level_1_no_0/kernel/read:02 up_level_1_no_0/random_uniform:08
m
up_level_1_no_0/bias:0up_level_1_no_0/bias/Assignup_level_1_no_0/bias/read:02up_level_1_no_0/Const:08
|
up_level_1_no_2/kernel:0up_level_1_no_2/kernel/Assignup_level_1_no_2/kernel/read:02 up_level_1_no_2/random_uniform:08
m
up_level_1_no_2/bias:0up_level_1_no_2/bias/Assignup_level_1_no_2/bias/read:02up_level_1_no_2/Const:08
|
up_level_0_no_0/kernel:0up_level_0_no_0/kernel/Assignup_level_0_no_0/kernel/read:02 up_level_0_no_0/random_uniform:08
m
up_level_0_no_0/bias:0up_level_0_no_0/bias/Assignup_level_0_no_0/bias/read:02up_level_0_no_0/Const:08
|
up_level_0_no_2/kernel:0up_level_0_no_2/kernel/Assignup_level_0_no_2/kernel/read:02 up_level_0_no_2/random_uniform:08
m
up_level_0_no_2/bias:0up_level_0_no_2/bias/Assignup_level_0_no_2/bias/read:02up_level_0_no_2/Const:08
`
features/kernel:0features/kernel/Assignfeatures/kernel/read:02features/random_uniform:08
Q
features/bias:0features/bias/Assignfeatures/bias/read:02features/Const:08
P
prob/kernel:0prob/kernel/Assignprob/kernel/read:02prob/random_uniform:08
A
prob/bias:0prob/bias/Assignprob/bias/read:02prob/Const:08
P
dist/kernel:0dist/kernel/Assigndist/kernel/read:02dist/random_uniform:08
A
dist/bias:0dist/bias/Assigndist/bias/read:02dist/Const:08

conv2d_transpose_1/kernel:0 conv2d_transpose_1/kernel/Assign conv2d_transpose_1/kernel/read:02conv2d_transpose_1/Const:08*Ц
serving_defaultВ
A
input8
input:0+џџџџџџџџџџџџџџџџџџџџџџџџџџџQ
outputG
concatenate_4/concat:0+џџџџџџџџџџџџџџџџџџџџџџџџџџџ!tensorflow/serving/predict