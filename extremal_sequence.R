rm(list=ls())

library(readxl)
library(openxlsx)
library(lubridate)

models_dir <- "E:/CMIP6/chazhi_result"
res_ev_dir <- "E:/CMIP6/JIZHI"
res_ds_dir <- "E:/CMIP6/chazhi_day/"

models <- c("EC-Earth3", "FGOALS-g3","TaiESM1")
SSPs <- c("hist", "SSP126", "SSP245", "SSP370", "SSP585")

# # 处理模式
# for (i in 1:length(models)){
#   data_dir <- paste(models_dir, models[i], sep = "/")
#   files <- list.files(data_dir, pattern = ".xlsx", recursive = F, full.names = F)
#   # 按照SSP将xlsx合并在一起
#   for (k in 1:length(SSPs)) {
#     j1 <- 0
#     for (j in 1:length(files)){
#       if (unlist(strsplit(files[j], "[_]"))[2] == SSPs[k]) {
#         j1 <- j1 + 1
#         setwd(data_dir)
#         file1 <- read_excel(files[j], col_names = paste("V", j1, sep = ""))
#         if (j1 == 1) {
#           file2 <- file1
#         } else {
#           file2 <- cbind(file2, file1)
#         }
#         
#       }
#     }
#     setwd(res_ds_dir)
#     write.xlsx(file2,paste(models[i], "_", SSPs[k], ".xlsx", sep = ""))
#   }
# }
# # 处理实测
# data_dir <- paste(models_dir, "Observation", sep = "/")
# files <- list.files(data_dir, pattern = ".xlsx", recursive = F, full.names = F)
# for (j in 1:length(files)){
#   setwd(data_dir)
#   file1 <- read_excel(files[j], col_names = paste("V", j, sep = ""))
#   if (j == 1) {
#     file2 <- file1
#   } else {
#     file2 <- cbind(file2, file1)
#   }
# }
# setwd(res_ds_dir)
# write.xlsx(file2,"Observation.xlsx")

files <- list.files(res_ds_dir, pattern = ".xlsx", recursive = F, full.names = F)
i <- 1
pr_daily <- read_excel(paste(res_ds_dir, files[i], sep = "/"))
# 不同情景的起止时间不同，需要判断并给出正确的开始~结束时间
if (unlist(strsplit(unlist(strsplit(files[i], "[_]"))[2], "[.]"))[1] == "hist") { # 历史为1964~2014
  startyear <- 1964
  endyear <- 2014
  starttime <- as.POSIXct(paste(startyear,'-','1','-','1',sep = ""))
  endtime <- as.POSIXct(paste(endyear,'-','12','-','31',sep = "")) # 起始时间根据数据序列设置
} else { # 情景为2015~2099
  startyear <- 2025
  endyear <- 2099
  starttime <- as.POSIXct(paste(startyear,'-','1','-','1',sep = ""))
  endtime <- as.POSIXct(paste(endyear,'-','12','-','31',sep = ""))
}
date <- as.Date(seq.POSIXt(starttime,endtime,by = "day"), tz = "asia/shanghai")
date <- as.character(date)

files <- list.files(res_ds_dir, pattern = ".xlsx", recursive = F, full.names = F)
for (i in 1:4) {
  # 读取序列
  pr_daily <- read_excel(paste(res_ds_dir, files[i], sep = "/"))
  # 不同情景的起止时间不同，需要判断并给出正确的开始~结束时间
  if (unlist(strsplit(unlist(strsplit(files[i], "[_]"))[2], "[.]"))[1] == "hist") { # 历史为1964~2014
    startyear <- 1964
    endyear <- 2014
    starttime <- as.POSIXct(paste(startyear,'-','1','-','1',sep = ""))
    endtime <- as.POSIXct(paste(endyear,'-','12','-','31',sep = "")) # 起始时间根据数据序列设置
  } else { # 情景为2015~2099
    startyear <- 2025
    endyear <- 2099
    starttime <- as.POSIXct(paste(startyear,'-','1','-','1',sep = ""))
    endtime <- as.POSIXct(paste(endyear,'-','12','-','31',sep = ""))
  }
  date <- as.Date(seq.POSIXt(starttime,endtime,by = "day"), tz = "asia/shanghai")
  date <- as.character(date)
  
  # 1.SDII
  years <- 1 # 年数
  SDII <- matrix(NA,years,length(pr_daily))
  SDII <- data.frame(
    rbind(variable.names(pr_daily),as.matrix(pr_daily[1:2,]),SDII)
  )
  rownames(SDII) <- c("ID","LON","LAT",startyear:endyear)
  # 2.R20mm
  R20mm <- matrix(NA,years,length(pr_daily))
  R20mm <- data.frame(
    rbind(variable.names(pr_daily),as.matrix(pr_daily[1:2,]),R20mm)
  )
  rownames(R20mm) <- c("ID","LON","LAT",startyear:endyear)
  # 3.CWD
  CWD <- matrix(NA,years,length(pr_daily))
  CWD <- data.frame(
    rbind(variable.names(pr_daily),as.matrix(pr_daily[1:2,]),CWD)
  )
  rownames(CWD) <- c("ID","LON","LAT",startyear:endyear)
  # 4.Rx5day
  Rx5day <- matrix(NA,years,length(pr_daily))
  Rx5day <- data.frame(
    rbind(variable.names(pr_daily),as.matrix(pr_daily[1:2,]),Rx5day)
  )
  rownames(Rx5day) <- c("ID","LON","LAT",startyear:endyear)
  
  for (m in 1:length(pr_daily)) {
    
    for (n in 1:length(startyear:endyear)) {
      year1 = n + startyear - 1
      pre <- as.numeric(as.matrix(pr_daily[which(year(date) == year1)+2,m]))
      pre[is.na(pre)] <- 0
      lon <- as.numeric(as.matrix(pr_daily[1,m]))
      lat <- as.numeric(as.matrix(pr_daily[2,m]))
      
      # 1.SDII
      pre_wet <- pre[which(pre >= 1)]
      Total_wet_day <- length(pre_wet)
      SDII[n+3,which(as.numeric(SDII[2,]) == lon & as.numeric(SDII[3,]) == lat)] <- sum(pre_wet)/Total_wet_day
      # 4.R20mm
      R20mm[n+3,which(as.numeric(R20mm[2,]) == lon & as.numeric(R20mm[3,]) == lat)] <- length(which(pre > 20))
      # 5.CWD
      jud <- 0
      CWD_temp <- vector()
      for (o in 1:length(pre)) {
        if (pre[o] < 1) {
          jud <- 0
        }else {
          jud <- jud + 1
        }
        CWD_temp[length(CWD_temp)+1] <- jud
      }
      CWD[n+3,which(as.numeric(CWD[2,]) == lon & as.numeric(CWD[3,]) == lat)] <- max(CWD_temp)
      # 8.Rx5day
      accum5_pre <- vector(length = length(pre)-4)
      for (o in 1:length(accum5_pre)) {
        accum5_pre[o] <- sum(pre[o:(o+4)])
      }
      Rx5day[n+3,which(as.numeric(Rx5day[2,]) == lon & as.numeric(Rx5day[3,]) == lat)] <- max(accum5_pre)
      
    }
    
  }
  # 写入SDII文件
  overwrite <- FALSE  # 根据需要设置是否允许覆盖
  
  for (file in files) {
    file_path_sdii <- file.path(res_ev_dir, "SDII", paste0("SDII_", file, ".xlsx"))
    file_path_r20mm <- file.path(res_ev_dir, "R20mm", paste0("R20mm_", file, ".xlsx"))
    file_path_cwd <- file.path(res_ev_dir, "CWD", paste0("CWD_", file, ".xlsx"))
    file_path_rx5day <- file.path(res_ev_dir, "Rx5day", paste0("Rx5day_", file, ".xlsx"))
    
    if (any(file.exists(file_path_sdii), file.exists(file_path_r20mm), file.exists(file_path_cwd), file.exists(file_path_rx5day)) & !overwrite) {
      print(paste(file, " already exists and overwrite is not allowed.", sep = ""))
    } else {
      setwd(file.path(res_ev_dir, "SDII"))
      write.xlsx(SDII, paste0("SDII_", file, ".xlsx"), colNames = FALSE)
      
      setwd(file.path(res_ev_dir, "R20mm"))
      write.xlsx(R20mm, paste0("R20mm_", file, ".xlsx"), colNames = FALSE)
      
      setwd(file.path(res_ev_dir, "CWD"))
      write.xlsx(CWD, paste0("CWD_", file, ".xlsx"), colNames = FALSE)
      
      setwd(file.path(res_ev_dir, "Rx5day"))
      write.xlsx(Rx5day, paste0("Rx5day_", file, ".xlsx"), colNames = FALSE)
      
      print(paste(file, " end!", sep = ""))
    }
  }
  
}

