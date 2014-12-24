#include <MyTestLib>

obj := new MyTestLib()
ret := obj.Test()
if (ret){
	msgbox Test Successful!
} else {
	msgbox Test Failed!
}