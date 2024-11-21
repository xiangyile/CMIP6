rm(list=ls())

library(tidyverse)
library(dplyr)
library(raster)
library(sf)
library(ncdf4)
library(openxlsx)

# 1.1 设置工作环境
data_dir <- "E:/CMIP6/"
res_dir <- "E:\\CMIP6\\CMIP6result"
setwd(data_dir)
getwd()

# 1.2 加载松辽流域范围的shp文件
SongliaoProjected <- st_read("Songliao_shapefile/songliao.shp")

# 2.1 确定批量提取的所有模式，以两个模式的两个情景为例
models <- list.dirs("./CMIP6data", recursive = F, full.names = F) # jupyter上有“.ipynb_checkpoints”这个文件夹，因此用“[-1]”在结果中去除；在window中不需要加“[-1]”
SSPs <- list.dirs(paste("./CMIP6data/", models[1], sep = ""), recursive = F, full.names = F)
print(models)
print(SSPs)

# 
error_files <- vector()

# 2.2 批量提取为txt
for (i in 1:length(models)) {
  if (models[i] != "FGOALS-g3") { # FGOALS-g3等模式与一般模式格式不一致，需要运行单独代码，详见else
    # 各模式所在路径
    path1 <- paste(data_dir, "CMIP6data", models[i], sep = "/")
    for (j in 1:length(SSPs)) {
      # 各模式各情景所在路径
      path2 <- paste(path1, SSPs[j], sep = "/")
      print(paste("开始提取", models[i], SSPs[j], sep = ":"))
      # 获取各模式各情景的nc文件名称
      files <- list.files(path2, pattern = ".nc", recursive = F, full.names = F)   
      for (k in 1:length(files)) {
        # 设置文件读取路径
        setwd(path2)
        # 每次循环处理的nc文件
        file1 <- files[k]
        print(paste("开始处理", file1, sep = ":"))
        # 裁剪出松辽流域内的nc文件
        raster_nc <- try(raster::brick(raster(file1)))
        if ("try-error" %in% class(raster_nc)) {
          print(paste("*********" ,file1, "文件出现问题", "*********", sep = ""))
          error_files[length(error_files)+1] <- file1
          next
        }
        mask_nc <- raster::mask(raster_nc, SongliaoProjected) # 读取松辽范围内的nc文件
        index_Songliao_girds <- which(raster_nc@data@values - mask_nc@data@values == 0) # 确定那些网格编号在松辽流域内
        # 提取nc文件内各网格对应的经纬度坐标
        data_nc <- as.data.frame(mask_nc, xy = TRUE)
        data_nc <- rename(data_nc,lon = x,lat = y)
        # 确定nc文件在松辽流域内对应的网格
        grids_nc <- dplyr::select(data_nc,-3)
        grids_nc <- grids_nc[index_Songliao_girds, ]
        rm(raster_nc, mask_nc, index_Songliao_girds, data_nc)
        
        # 读取nc文件并按照时间依次提取各网格的降水数据
        brick_nc <- brick(file1)
        for (m in 1:length(grids_nc$lon)) {
          setwd(path2)
          # 将数据框形式的坐标转为空间点形式
          sp_grid <- SpatialPoints(grids_nc[m, ])
          # 提取各文件各网格的降水序列，注意CMIP6模式降水数据的单位是kg/m^2/s，转换为日降水量需要*3600*24
          prseries <- as.data.frame(
            t(raster::extract(brick_nc,sp_grid))*3600*24
          )
          # 给出降水序列对应的时间
          prdate <- rownames(prseries)
          prdate <- unlist(strsplit(prdate, 'X'))[seq(2,length(prdate)*2,2)]
          years <- unlist(strsplit(prdate,'[.]'))[seq(1,length(prdate)*3,3)]
          months <- unlist(strsplit(prdate,'[.]'))[seq(2,length(prdate)*3,3)]
          days <- unlist(strsplit(prdate,'[.]'))[seq(3,length(prdate)*3,3)]
          rownames(prseries) <- as.Date(paste(years, months, days, sep = '-'))
          
          rm(prdate, years, months, days)
          
          
          # 拼接出各网格的长序列
          prseries2 <- prseries
          info <- data.frame(V1 = c(m, round(grids_nc[m,1],2), round(grids_nc[m,2],2)))
          rownames(info) <- c("ID", "lon", "lat")
          prseries2 <- rbind(info, prseries2)
          rm(info)
          if (m == 1) {
            prseries1 <- prseries2
          }else{
            prseries1 <- cbind(prseries1, prseries2)
          }
        }
        
        if (k-length(error_files) == 1) {
          prresult <- prseries1
        } else {
          prresult <- rbind(prresult, prseries1[-(1:3),])
        }
      }
      setwd(res_dir)
      write.xlsx(prresult, paste("raw_", models[i], "_", SSPs[j], ".xlsx", sep = ""), rowNames = F, colNames = F)
      print(paste("提取完毕", models[i], SSPs[j], sep = "-"))
    }
  } else { # FGOALS-g3
    # 各模式所在路径
    path1 <- paste(data_dir, "CMIP6data", models[i], sep = "/")
    for (j in 1:length(SSPs)) {
      # 各模式各情景所在路径
      path2 <- paste(path1, SSPs[j], sep = "/")
      print(paste("开始提取", models[i], SSPs[j], sep = ":"))
      # 获取各模式各情景的nc文件名称
      files <- list.files(path2, pattern = ".nc", recursive = F, full.names = F)   
      for (k in 1:length(files)) {
        # 设置文件读取路径
        setwd(path2)
        # 每次循环处理的nc文件
        file1 <- files[k]
        print(paste("开始处理", file1, sep = ":"))
        # 裁剪出松辽流域内的nc文件
        nc_data <- nc_open(file1) # 读取原始的全球范围nc文件
        lon <- ncvar_get(nc_data,varid = 'lon')
        lat <- ncvar_get(nc_data,varid = 'lat')
        
        m <- 0
        for (i_lon in 115:136) { # 115:136为松辽流域经度范围
          if (lon[i_lon] >= 115 &lon[i_lon] <= 136) { # 与上一致
            for (i_lat in 38:54) { # 38:54为松辽流域纬度范围
              if (lat[i_lat] >= 38 &lat[i_lat] <= 54) { # 与上一致
                m <- m+1 
                prseries <- as.data.frame(ncvar_get(nc_data,varid = 'pr')[i_lon,i_lat,]*3600*24) # 提取的序列
                startyear <- 2014+i_file # 以FGOALS-g3为例，每个nc文件包含一年的数据，如果其他模式格式不同，此行需要修改
                starttime <- as.POSIXct(paste(startyear,'-',1,'-',1,sep = "")) # 以FGOALS-g3为例，每个nc文件包含一年的数据，如果其他模式格式不同，此行需要修改
                endtime <- as.POSIXct(paste(startyear,'-',12,'-',31,sep = "")) # 以FGOALS-g3为例，每个nc文件包含一年的数据，如果其他模式格式不同，此行需要修改
                prdate <- as.Date(seq.POSIXt(starttime,endtime,by="day"), tz = "asia/shanghai") # 序列对应的时间
                if (startyear%%4 ==0) { # 以FGOALS-g3为例，模拟的闰年也只有365天，需要把2月29日补上，对于极值序列则补为0
                  prseries <- data.frame(t1 = c(prseries[1:58,],0,prseries[59:365,]))
                }
                rownames(prseries) <- prdate
                colnames(prseries) <- "pr"                               
                # 拼接出各网格的长序列
                prseries2 <- prseries
                info <- data.frame(V1 = c(m, round(grids_nc[m,1],2), round(grids_nc[m,2],2)))
                rownames(info) <- c("ID", "lon", "lat")
                prseries2 <- rbind(info, prseries2)
                rm(info)
                if (m == 1) {
                  prseries1 <- prseries2
                }else{
                  prseries1 <- cbind(prseries1, prseries2)
                }
                
                
              }
            }
          }
        }
        
        if (k-length(error_files) == 1) {
          prresult <- prseries1
        } else {
          prresult <- rbind(prresult, prseries1[-(1:3),])
        }
        nc_close(nc_data)
      }
      setwd(res_dir)
      write.xlsx(prresult, paste("raw_", models[i], "_", SSPs[j], ".xlsx", sep = ""), rowNames = F, colNames = F)
      print(paste("提取完毕", models[i], SSPs[j], sep = "-"))
    }
  }
}
print("全部提取完毕")
write.table(data.frame(error_files), "error_files.txt", col.names = F, row.names = F)