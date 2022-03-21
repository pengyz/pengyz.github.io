---
title: OpenGL编程入门： 1.Ubuntu下开发环境搭建
date: 2017-09-02 17:05:02
updated: 2017-09-02 17:05:02
tags:
- 计算机图形学
- OpenGL编程入门
categories:
- 计算机图形学
- OpenGL
---

# 计算机图形学与OpenGL


[计算机图形学](https://baike.baidu.com/item/%E8%AE%A1%E7%AE%97%E6%9C%BA%E5%9B%BE%E5%BD%A2%E5%AD%A6/279486?fr=aladdin)主要研究如何在计算机中显示丰富多彩的二维和三维图形。受益于计算机图形学的发展和图形硬件性能的飞速提升，各种游戏大作的绚丽画面令人瞠目结舌。而近两年[虚拟现实(VR)](https://baike.baidu.com/item/%E8%99%9A%E6%8B%9F%E7%8E%B0%E5%AE%9E/207123?fr=aladdin)和[增强现实(AR)](https://baike.baidu.com/item/%E5%A2%9E%E5%BC%BA%E7%8E%B0%E5%AE%9E/1889025)的兴起，配合着早已到来的移动互联网时代，更是让人们看到了计算机图形学所带来的未来科技的魅力。

在图形学编程中，计算机图形学是基础，其背后的数学原理指导我们如何将三维物体空间投射到二维屏幕空间并展现出真实的空间感。有了理论基础，我们就需要某种方法，将这种理论转化为切实的计算机程序，将画面加以呈现。这个过程中，程序员需要某种方式，可以和计算机的图形显卡进行通信，将显示数据送入显存，并告知显卡这些数据的含义，最终由显卡进行渲染，最终呈现出画面。

<!-- more -->

OpenGL正是基于这种目的所创建。它提供了一组标准的接口，用于沟通显卡，使得我们可以传送数据到显存并指定传入数据的格式。高版本OpenGL提供的可编程管线赋予了程序员对渲染流程的控制能力，以便绘制更复杂的画面和提供对渲染过程的更强的控制能力。

OpenGL被认为是一种底层图形API编程接口，它支持所有的主流操作系统平台。它的一个简化版本OpenGL ES被广泛应用于Android系统中，是移动互联网时代图形处理的核心解决方案，
当然，相较于竞争对手DirectX，OpenGL也许在易用性，效率等方面受到很多诟病，但它依然是我们接触和学习计算机图形学最好的切入点。

# 关于beginners苦苦搜寻的'OpenGL SDK'的一点说明


程序员对于SDK的概念都是耳熟能详的。隔壁DirectX就有微软爸爸提供的SDK啊，下载安装，按照guide开始搞就好了。所以对于OpenGL，很多新手的第一反应是：**去哪下SDK**？

这里有一个'**非常不幸**'的消息告诉大家： OpenGL没有SDK，官方不提供任何的二进制开发包。

至于这个问题的原因，在于OpenGL是一个底层图形库，它的*底层*体现在它提供对显卡的操作性。OpenGL的功能是独立于操作系统之外的，它的图形功能本身依赖于显卡而不是操作系统。这一点上，OpenGL和我们熟知的图形UI库，比如MFC，QT，又或者Java Swing ，C#等有本质的不同。

OpenGL可以说是一套标准，这套标准描述了OpenGL所提供的API接口集合，而对它的具体实现，则由显卡厂商来完成。也就是说，你找不到所谓的“OpenGL支持库”，也不存在SDK。它的功能直接实现在Nvidia或者ATI显卡驱动中。显卡厂商会在自家的显卡上实现OpenGL的某个特定版本并以官方驱动的形式提供给用户下载。对于普通用户来说，只需要安装新版的显卡驱动即可，无需安装其他任何东西。这也是为什么游戏玩家经常需要安装DirectX9C什么的，却很少见到有“安装OpenGL”这个说法，对于OpenGL游戏黑屏之类的问题，你要做的是升级显卡驱动。


# OpenGL开发三件套： GLEW，GLFW，GLM


OpenGL的开发环境其实配置起来是要花点精力的。问题就在于，如何获取OpenGL的编程接口。因为我们有的，只是驱动厂商提供的二进制驱动程序，并没有任何的依赖库，或者头文件。那么开发工作怎么开始呢？

常规的做法是，从厂商的显卡驱动程序中手动获取OpenGL的导出函数地址。这是一个很繁琐的工作，我们需要手动获取到常用的OpenGL函数的函数地址，并声明为正确的函数指针格式。对于不同的显卡设备和显卡驱动版本，所支持的OpenGL版本各不相同，有些API可能在旧版本驱动中并未提供。另外一个导致这个问题复杂化的原因是OpenGL扩展。不同的厂商可能针对标准OpenGL有自己的扩展函数提供。这些函数并不包含在标准的OpenGL中，通常用来提供一些显卡相关的高级特性或者用来针对特定显卡提供效率优化。对于这部分扩展函数的处理是非常重复，繁琐和复杂的劳动。

所以我们有了[GLEW](http://glew.sourceforge.net/)库，全称是“The OpenGL Extension Wrangler Library”,专门用来处理OpenGL扩展。我们只需要调用一个glewInit函数，便可以自动获取当前显卡所支持的所有扩展。

对比DirectX，其实OpenGL提供的功能要简单的多，它只提供了对图形的处理功能，并没有提供和窗口创建，鼠标键盘输入处理等相关的功能。所以我们需要一个跨平台的窗口类库实现以配合OpenGL实现跨平台图形程序的编写。[GLFW](http://www.glfw.org/)正是这样一个类库，它为OpenGL/OpenGL ES/Vulkan提供了跨平台的统一接口，用以实现基本窗口创建和输入处理。

在开发过程中，我们会涉及一些矩阵转换，投影，缩放等数学内容，所以我们需要一个数学库来简化这些操作。[GLM](https://github.com/g-truc/glm)可以用来解决这问题,它提供了一个和GLSL相似的语法用来处理OpenGL中常见的数学运算。

在ubuntu系统中，我们可以使用如下命令安装这三个依赖库：
````bash
sudo apt install -y libglew-dev libglfw3-dev libglm-dev
````


# 构建工具链和IDE的选择

对于Linux系统上的**现代C++**项目来说，CMake永远是构建工具最有力的竞争者之一。关于CMake的具体语法和它解决了什么问题，各位看官感兴趣的可以去百度。但是CMake确实很优秀，语法简洁明了，跨平台，支持不同的编译器。
对于IDE的选择，qt creator和CLion都不错。它们都支持cmake工程，提供完善的语法提示和IDE调试功能。

个人更倾向于CLion，毕竟是付费产品，它提供的功能更完备：语法补全，错误提示，头文件自动引入等等，带给你的是一个足够爽快的编程体验。当然，作为idea系列的产品，它依赖于java，而且相对资源占用较多。在我的系统上，它还有一很影响使用体验的小bug：导航快捷键不管用。每次都要去菜单上点真的很烦。除此之外，一切都很完美。


# 一个简单的示例程序

下面是一个简单的例子程序，用来显示一个彩色立方体。

{% codeblock lang:cpp main.cpp %}
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include "glShader.h"
#include <iostream>
#include <string>
#include "glShader.h"
#include "glTexture.h"


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

// the struct to hold all values we have used.
// just use glfwSetWindowUserPointer to bind it to the GLFWwindow pointer.
struct window_info{
    int width;
    int height;
    std::string title;
    GLuint vertexArrayId;
    GLuint vertexbuffer;            //identify for vertex buffer
    GLuint uvbuffer;                //identify for uv buffer
    GLuint programId;               //the shader program identify we used
    GLint matrixId;                 //matrix location
    glm::mat4 mvpMatrix;            //Model-View-Projection matrix that we need translate to shader
    GLuint texture;                 //texture we have loaded, Sampler2D
    GLuint textureId;               //texture location
};


void initFunc(GLFWwindow *window)
{
    window_info *info = static_cast<window_info*>(glfwGetWindowUserPointer(window));
    if(!info){
        std::cerr << "initFunc: get info failed !" << std::endl;
        return;
    }

    // Our vertices. Tree consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
    // A cube has 6 faces with 2 triangles each, so this makes 6*2=12 triangles, and 12*3 vertices
    static const GLfloat g_vertex_buffer_data[] = {
            -1.0f,-1.0f,-1.0f,
            -1.0f,-1.0f, 1.0f,
            -1.0f, 1.0f, 1.0f,
            1.0f, 1.0f,-1.0f,
            -1.0f,-1.0f,-1.0f,
            -1.0f, 1.0f,-1.0f,
            1.0f,-1.0f, 1.0f,
            -1.0f,-1.0f,-1.0f,
            1.0f,-1.0f,-1.0f,
            1.0f, 1.0f,-1.0f,
            1.0f,-1.0f,-1.0f,
            -1.0f,-1.0f,-1.0f,
            -1.0f,-1.0f,-1.0f,
            -1.0f, 1.0f, 1.0f,
            -1.0f, 1.0f,-1.0f,
            1.0f,-1.0f, 1.0f,
            -1.0f,-1.0f, 1.0f,
            -1.0f,-1.0f,-1.0f,
            -1.0f, 1.0f, 1.0f,
            -1.0f,-1.0f, 1.0f,
            1.0f,-1.0f, 1.0f,
            1.0f, 1.0f, 1.0f,
            1.0f,-1.0f,-1.0f,
            1.0f, 1.0f,-1.0f,
            1.0f,-1.0f,-1.0f,
            1.0f, 1.0f, 1.0f,
            1.0f,-1.0f, 1.0f,
            1.0f, 1.0f, 1.0f,
            1.0f, 1.0f,-1.0f,
            -1.0f, 1.0f,-1.0f,
            1.0f, 1.0f, 1.0f,
            -1.0f, 1.0f,-1.0f,
            -1.0f, 1.0f, 1.0f,
            1.0f, 1.0f, 1.0f,
            -1.0f, 1.0f, 1.0f,
            1.0f,-1.0f, 1.0f
    };

    // Two UV coordinatesfor each vertex. They were created with Blender.
    static const GLfloat g_uv_buffer_data[] = {
            0.000059f, 1.0f-0.000004f,
            0.000103f, 1.0f-0.336048f,
            0.335973f, 1.0f-0.335903f,
            1.000023f, 1.0f-0.000013f,
            0.667979f, 1.0f-0.335851f,
            0.999958f, 1.0f-0.336064f,
            0.667979f, 1.0f-0.335851f,
            0.336024f, 1.0f-0.671877f,
            0.667969f, 1.0f-0.671889f,
            1.000023f, 1.0f-0.000013f,
            0.668104f, 1.0f-0.000013f,
            0.667979f, 1.0f-0.335851f,
            0.000059f, 1.0f-0.000004f,
            0.335973f, 1.0f-0.335903f,
            0.336098f, 1.0f-0.000071f,
            0.667979f, 1.0f-0.335851f,
            0.335973f, 1.0f-0.335903f,
            0.336024f, 1.0f-0.671877f,
            1.000004f, 1.0f-0.671847f,
            0.999958f, 1.0f-0.336064f,
            0.667979f, 1.0f-0.335851f,
            0.668104f, 1.0f-0.000013f,
            0.335973f, 1.0f-0.335903f,
            0.667979f, 1.0f-0.335851f,
            0.335973f, 1.0f-0.335903f,
            0.668104f, 1.0f-0.000013f,
            0.336098f, 1.0f-0.000071f,
            0.000103f, 1.0f-0.336048f,
            0.000004f, 1.0f-0.671870f,
            0.336024f, 1.0f-0.671877f,
            0.000103f, 1.0f-0.336048f,
            0.336024f, 1.0f-0.671877f,
            0.335973f, 1.0f-0.335903f,
            0.667969f, 1.0f-0.671889f,
            1.000004f, 1.0f-0.671847f,
            0.667979f, 1.0f-0.335851f
    };


    //load dds texture
    info->texture = loadDDS("../resources/textures/uvtemplate.DDS");
    std::cout << "texture: " << info->texture << std::endl;
    info->textureId = glGetUniformLocation(info->programId,"myTextureSampler");
    std::cout << "textureId: " << info->textureId << std::endl;


    glGenVertexArrays(1,&info->vertexArrayId);
    glBindVertexArray(info->vertexArrayId);
    //gen buffer
    glGenBuffers(1, &info->vertexbuffer); //gen 1 buffer,saved in vertexbuffer
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, info->vertexbuffer);    //bind the generated buffer, otherwise the following operation will take effect on it.
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);
    glVertexAttribPointer(
            0,//same as the bind location
            3,//size of the array element, just 3 float makes a point.
            GL_FLOAT,//we use float for point
            GL_FALSE,//not normalize
            0,//stride
            (void*)0//array buffer offset.
    );
    glGenBuffers(1, &info->uvbuffer);
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, info->uvbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_uv_buffer_data), g_uv_buffer_data, GL_STATIC_DRAW);
    glVertexAttribPointer(
            1,
            2,
            GL_FLOAT,
            GL_FALSE,
            0,
            (void*)0
    );

    glBindVertexArray(0);
    info->programId = Misc::loadShader("../resources/shaders/TexturedClubVertex.glsl","../resources/shaders/TexturedClubFrag.glsl");
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glUseProgram(info->programId);
    //let's create the MVP matrix!
    glm::mat4 projectionMartrix = glm::perspective(glm::radians(45.0f),(float)info->width / (float)info->height,0.1f, 100.0f);
//    glm::mat4 projectionMartrix = glm::ortho(-10.0f,10.0f,-10.0f,10.0f,0.0f,100.0f); // In world coordinates
    glm::mat4 viewMatrix = glm::lookAt(
            glm::vec3(4,3,3),
            glm::vec3(0,0,0),
            glm::vec3(0,1,0)
    );
    glm::mat4 modelMatrix = glm::mat4( 1.0f);
    //wtf? clion give the wrong warning...
    info->mvpMatrix = projectionMartrix * viewMatrix * modelMatrix;
    info->matrixId = glGetUniformLocation(info->programId, "MVP");
    std::cout << "initFunc success !" << std::endl;
}


void drawFunc(GLFWwindow *window){
    window_info* info = static_cast<window_info*>(glfwGetWindowUserPointer(window));
    if(!info){
        std::cerr << "drawFunc: get info failed !";
        return;
    }

    glfwGetWindowSize(window, &info->width, &info->height);
    glViewport(0,0,info->width,info->height);


    glUseProgram(info->programId);

    glUniformMatrix4fv(info->matrixId, 1, GL_FALSE, &info->mvpMatrix[0][0]);
    //I don't understand it now.
    //how to relate texture and it's location?
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, info->texture);
    glUniform1i(info->textureId, 0);

    glUniformMatrix4fv(info->matrixId, 1, GL_FALSE, &info->mvpMatrix[0][0]);
    glBindVertexArray(info->vertexArrayId);

    glDrawArrays(GL_TRIANGLES,0, 12 * 3);

    glBindVertexArray(0);
    glUseProgram(0);
}


void cleanFunc(GLFWwindow *window){
    window_info *info = static_cast<window_info*>(glfwGetWindowUserPointer(window));
    if(!info){
        std::cerr << "cleanFun: get info failed !" << std::endl;
        return;
    }
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDeleteBuffers(1,&info->vertexbuffer);
    glDeleteBuffers(1, &info->uvbuffer);
    glDeleteVertexArrays(1,&info->vertexArrayId);
    glDeleteProgram(info->programId);
    glDeleteTextures(1, &info->texture);
    //delete info
    glfwSetWindowUserPointer(window, nullptr);
    delete info;
    //destory window
    glfwMakeContextCurrent(nullptr);
    glfwDestroyWindow(window);
    std::cout << "cleanFunc success !" << std::endl;
}

int main(int argc, const char** argv){

    glfwSetErrorCallback([](int errorCode, const char* errorMsg){
        std::cerr << "[" << errorCode << "] " << errorMsg <<  std::endl;
    });
    if(!glfwInit()){
        std::cerr << "glfwInit failed !" << std::endl;
        return -1;
    }

    glfwWindowHint(GLFW_SAMPLES, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    window_info *info = new window_info;
    info->width = 800;
    info->height = 600;
    info->title = "ogl-toturial-texture-clube";
    GLFWwindow *window = glfwCreateWindow(info->width,info->height,info->title.c_str(),nullptr, nullptr);
    if(!window){
        delete info;
        std::cout << "glfwCreateWindow failed !" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwSetWindowUserPointer(window,info);
    glfwMakeContextCurrent(window);
    glewExperimental = GL_TRUE;
    if(GLEW_OK != glewInit()){
        glfwTerminate();
        std::cerr << "glewInit failed !" << std::endl;
        return -1;
    }
    //初始化
    initFunc(window);

    while (!glfwWindowShouldClose(window)){
        glfwPollEvents();
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        //绘制
        drawFunc(window);
        //swap buffer
        glfwSwapBuffers(window);
    }
    //清理
    cleanFunc(window);
    glfwTerminate();
    return 0;
}
{% endcodeblock %}





{%codeblock lang:glsl TexturedClubVertex.glsl %}
#version 330 core

layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec2 vertexUV;

out vec2 UV;

uniform mat4 MVP;

void main(){
  gl_Position = MVP * vec4(vertexPosition_modelspace, 1);

  UV = vertexUV;
}
{%endcodeblock%}


{%codeblock lang:glsl TexturedClubFrag.glsl%}
#version 330 core

in vec2 UV;

out vec3 color;

uniform sampler2D myTextureSampler;

void main(){

  //Output color = color of the texture at the specific UV
  color = texture(myTextureSampler, UV).rgb;
}
{%endcodeblock%}
