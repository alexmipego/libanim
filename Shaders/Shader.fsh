//
//  Shader.fsh
//  anim
//
//  Created by Alexandre on 8/7/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
